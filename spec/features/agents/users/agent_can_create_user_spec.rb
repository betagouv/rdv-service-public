RSpec.describe "Agent can create user" do
  let!(:organisation) { create(:organisation, name: "MDS des Champs", territory: territory) }
  let!(:territory) { create(:territory, enable_notes_field: true) }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let!(:user) do
    create(:user, first_name: "Jean", last_name: "LEGENDE", email: "jean@legende.com", organisations: [organisation])
  end

  around { |example| perform_enqueued_jobs { example.run } }

  before do
    login_as(agent, scope: :agent)
    visit "http://www.rdv-aide-numerique-test.localhost/"
    click_link "Usagers"
    click_link "Ajouter un usager", match: :first
    expect_page_title("Nouvel usager")
  end

  it "works" do
    fill_in :user_first_name, with: "Marco"
    fill_in :user_last_name, with: "Lebreton"
    fill_in "Remarques", with: "souhaite participer au prochain atelier collectif"
    click_on "Enregistrer"
    expect_page_title("Marco LEBRETON")

    user = User.last
    expect(user.annotation_for(organisation.territory)).to eq "souhaite participer au prochain atelier collectif"
  end

  context "user already exists in other organisation of the same territory" do
    let!(:existing_user) do
      create(:user, first_name: "Cee-Lo", last_name: "GREEN", email: "ceelo@green.com", organisations: [create(:organisation, territory:)])
    end

    it "allows using existing user" do
      fill_in :user_first_name, with: "Cee-Lo"
      fill_in :user_last_name, with: "Green"
      fill_in :user_email, with: "ceelo@green.com"
      click_on "Enregistrer"
      expect(page).to have_content("Un usager avec le même email a déjà un compte sur RDV Service Public")
      click_link "Importer cet usager"
      expect_page_title("Cee-Lo GREEN")
      expect(page).to have_content("L'usager a été associé à votre organisation.")
      expect(existing_user.reload.organisations).to include(organisation)
    end
  end

  it "permet de désactiver les préférences de notifications mails et SMS" do
    fill_in :user_first_name, with: "Marco"
    fill_in :user_last_name, with: "Lebreton"
    fill_in "Email", with: "marco@lebreton.bzh"
    fill_in "Téléphone", with: "0606060606"
    uncheck "Accepte les notifications par email"
    uncheck "Accepte les notifications par SMS"
    click_on "Enregistrer"
    expect(find("span", text: /Accepte les notifications par email/).ancestor("li")).to have_content("Désactivées")
    expect(find("span", text: /Accepte les notifications par SMS/).ancestor("li")).to have_content("Désactivées")
  end

  context "champ complément d’adresse activé sur le territoire", js: true do
    let!(:territory) { create(:territory, enable_address_field: true, enable_address_details: true) }

    it "permet de créer un usager avec juste nom-prénom" do
      fill_in :user_first_name, with: "Marco"
      fill_in :user_last_name, with: "Lebreton"
      click_on "Enregistrer"
      expect_page_title("Marco LEBRETON")
    end
  end
end
