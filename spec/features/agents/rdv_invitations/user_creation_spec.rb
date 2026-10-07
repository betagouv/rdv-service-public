RSpec.describe "Création d'usager lors des invitations" do
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let(:organisation) { create(:organisation) }
  let!(:motif) { create(:motif, organisation:) }

  before { login_as agent, scope: :agent }

  it "ajoute l'usager à l'organisation" do
    visit edit_user_admin_organisation_rdv_invitations_path(organisation)
    click_on "Ajouter un usager"

    fill_in "Prénom", with: "Francis"
    fill_in "Nom d’usage", with: "Factice"

    fill_in "Email", with: "francis@factice.org"
    click_on "Enregistrer"

    expect(page).to have_content "Nous allons envoyer une invitation à Francis FACTICE"

    expect(User.last).to have_attributes(
      first_name: "Francis",
      last_name: "Factice",
      email: "francis@factice.org",
      organisations: [organisation]
    )
  end
end
