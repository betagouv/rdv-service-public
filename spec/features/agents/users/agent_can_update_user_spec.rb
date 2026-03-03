RSpec.describe "Agent can update user" do
  let!(:organisation) { create(:organisation) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let!(:user) do
    create(:user, first_name: "Jean", last_name: "LEGENDE", email: "jean@legende.com", organisations: [organisation])
  end

  around { |example| perform_enqueued_jobs { example.run } }

  before do
    login_as(agent, scope: :agent)
    visit authenticated_agent_root_path
    visit admin_organisation_user_path(organisation, user)
  end

  it "update existing user's email" do
    within("#spec-primary-user-card") { click_link "Modifier" }
    fill_in :user_first_name, with: "jeanne"
    fill_in :user_last_name, with: "reynolds"
    fill_in "Email", with: "jeanne@reynolds.com"
    click_button "Enregistrer"
    # When the user has already a pwd, changing email send a confirmation email
    open_email("jeanne@reynolds.com")
    expect(current_email.subject).to eq "Instructions de confirmation de votre nouvelle adresse email"
    expect_page_title("jeanne REYNOLDS")
    expect(page).to have_content("En attente de confirmation pour jeanne@reynolds.com")
  end

  describe "optional fields" do
    let!(:organisation) { create(:organisation, territory: territory) }

    context "when they are disabled" do
      let(:territory) { create(:territory, enable_notes_field: false, enable_caisse_affiliation_field: false) }

      it "doesn't show them them" do
        within("#spec-primary-user-card") { click_link "Modifier" }
        expect(page).not_to have_content("Remarques")
        expect(page).not_to have_content("Caisse d'affiliation")
      end
    end

    context "when they are enabled" do
      let(:territory) { create(:territory, enable_notes_field: true, enable_caisse_affiliation_field: true) }
      let!(:annotation_in_current_territory) do
        Annotation.create!(user: user, territory: territory, content: "Remarques du territoire courant")
      end
      let!(:annotation_in_other_territory) do
        Annotation.create!(user: user, territory: other_territory, content: "Remarques de l'autre territoire")
      end
      let(:other_territory) { create(:territory) }

      before do
        # On ajoute l'usager dans un autre territoire pour vérifier que ses annotations sont mises à jour dans un seul territoire
        create(:user_profile, user: user, organisation: create(:organisation, territory: other_territory))
      end

      it "update user annotations" do
        within("#spec-primary-user-card") { click_link "Modifier" }
        expect(page).to have_field("Remarques", with: "Remarques du territoire courant")

        fill_in "Remarques", with: "souhaite participer au prochain atelier collectif"
        select "MSA", from: "Caisse d'affiliation"
        click_button "Enregistrer"
        expect(user.reload.annotation_for(territory)).to eq "souhaite participer au prochain atelier collectif"
        expect(user.reload.caisse_affiliation).to eq "msa"
        expect(user.reload.annotation_for(other_territory)).to eq "Remarques de l'autre territoire"
        expect(page).to have_content("souhaite participer au prochain atelier collectif")
      end
    end
  end

  context "unregistered user" do
    let!(:user) do
      create(:user, :unregistered, first_name: "Jean", last_name: "LEGENDE", email: nil, organisations: [organisation])
    end

    it "add email to existing user" do
      within("#spec-primary-user-card") { click_link "Modifier" }
      fill_in "Email", with: "jean@legende.com"
      click_button "Enregistrer"
      expect(page).to have_content("jean@legende.com")
    end
  end

  context "usager n’a pas encore confirmé son compte" do
    # lorsqu’un usager a confirmé son compte, l’agent n’a plus la main sur ses préférences de notifs
    let!(:user) { create(:user, :unconfirmed, organisations: [organisation]) }

    it "permet de désactiver et réactiver les préférences de notifications SMS et email" do
      within("#spec-primary-user-card") { click_link "Modifier" }
      expect(page).to have_content("Modifier l'usager")
      expect(page).to have_checked_field("Accepte les notifications par email")
      expect(page).to have_checked_field("Accepte les notifications par SMS")
      uncheck "Accepte les notifications par email"
      uncheck "Accepte les notifications par SMS"
      click_button "Enregistrer"
      expect(find("span", text: /Accepte les notifications par email/).ancestor("li")).to have_content("Désactivées")
      expect(find("span", text: /Accepte les notifications par SMS/).ancestor("li")).to have_content("Désactivées")
      within("#spec-primary-user-card") { click_link "Modifier" }
      expect(page).to have_unchecked_field("Accepte les notifications par email")
      expect(page).to have_unchecked_field("Accepte les notifications par SMS")
      check "Accepte les notifications par email"
      check "Accepte les notifications par SMS"
      click_button "Enregistrer"
      expect(find("span", text: /Accepte les notifications par email/).ancestor("li")).to have_content("Activées")
      expect(find("span", text: /Accepte les notifications par SMS/).ancestor("li")).to have_content("Activées")
    end
  end
end
