# frozen_string_literal: true

describe "Agent can create user" do
  let!(:organisation) { create(:organisation, name: "MDS des Champs") }
  let!(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let!(:user) do
    create(:user, first_name: "Jean", last_name: "LEGENDE", email: "jean@legende.com", organisations: [organisation])
  end

  around { |example| perform_enqueued_jobs { example.run } }

  before do
    login_as(agent, scope: :agent)
    visit "http://www.rdv-aide-numerique-test.localhost/"
    click_link "Usagers"
    click_link "Créer un usager", match: :first
    expect_page_title("Nouvel usager")
  end

  it "works" do
    fill_in :user_first_name, with: "Marco"
    fill_in :user_last_name, with: "Lebreton"
    click_button "Créer"
    expect_page_title("Marco LEBRETON")
    expect(page).to have_no_content("Inviter")
    within("#spec-primary-user-card") { click_link "Modifier" }
    fill_in "Email", with: "marco@lebreton.bzh"
    click_button "Enregistrer"
    click_link "Inviter"
    open_email("marco@lebreton.bzh")
    expect(current_email.subject).to eq("Vous avez été invité sur RDV Aide Numérique")
  end

  context "user already exists in other organisation" do
    let!(:existing_user) do
      create(:user, first_name: "Cee-Lo", last_name: "GREEN", email: "ceelo@green.com", organisations: [create(:organisation)])
    end

    it "allows using existing user" do
      fill_in :user_first_name, with: "Cee-Lo"
      fill_in :user_last_name, with: "Green"
      fill_in :user_email, with: "ceelo@green.com"
      click_button "Créer"
      expect(page).to have_content("Un usager avec le même email a déjà un compte sur RDV Solidarités")
      click_link "Importer cet usager"
      expect_page_title("Cee-Lo GREEN")
      expect(page).to have_content("L'usager a été associé à votre organisation.")
      expect(existing_user.reload.organisations).to include(organisation)
    end
  end
end
