# frozen_string_literal: true

describe "Agent can update user" do
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
    within("#spec-primary-user-card") { click_link "Modifier" }
  end

  it "update existing user's email" do
    fill_in :user_first_name, with: "jeanne"
    fill_in :user_last_name, with: "reynolds"
    fill_in "Email", with: "jeanne@reynolds.com"
    click_button "Enregistrer"
    # When the user has already a pwd, changing email send a confirmation email
    open_email("jeanne@reynolds.com")
    expect(current_email.subject).to eq I18n.t("devise.mailer.confirmation_instructions.subject")
    expect_page_title("jeanne REYNOLDS")
    expect(page).to have_content("En attente de confirmation pour jeanne@reynolds.com")
  end

  describe "optional fields" do
    let!(:organisation) { create(:organisation, territory: territory) }

    context "when they are disabled" do
      let(:territory) { create(:territory, enable_notes_field: false, enable_caisse_affiliation_field: false) }

      it "doesn't show them them" do
        expect(page).not_to have_content("Remarques")
        expect(page).not_to have_content("Caisse d'affiliation")
      end
    end

    context "when they are enabled" do
      let(:territory) { create(:territory, enable_notes_field: true, enable_caisse_affiliation_field: true) }

      it "update user notes" do
        fill_in "Remarques", with: "souhaite participer au prochain atelier collectif"
        select "MSA", from: "Caisse d'affiliation"
        click_button "Enregistrer"
        expect(user.reload.notes).to eq "souhaite participer au prochain atelier collectif"
        expect(user.reload.caisse_affiliation).to eq "msa"
      end
    end
  end

  context "unregistered user" do
    let!(:user) do
      create(:user, :unregistered, first_name: "Jean", last_name: "LEGENDE", email: nil, organisations: [organisation])
    end

    it "add email to existing user" do
      fill_in "Email", with: "jean@legende.com"
      click_button "Enregistrer"
      click_link "Inviter"
      open_email("jean@legende.com")
      expect(current_email.subject).to eq "Vous avez été invité sur RDV Solidarités"
    end
  end
end
