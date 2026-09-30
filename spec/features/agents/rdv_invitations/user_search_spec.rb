RSpec.describe "Recherche d'usager pour les invitations" do
  let(:agent) { create(:agent, basic_role_in_organisations: [organisation]) }
  let(:organisation) { create(:organisation) }

  let(:user) { create(:user, :francis_factice, organisations: [organisation]) }

  before { login_as agent, scope: :agent }

  it "permet de chercher parmis les usagers de l'organisation", js: true do
    visit edit_user_admin_organisation_rdv_invitations_path(organisation)

    fill_in :user_id, with: "Fra"
    expect(page).to have_content "Francis FACTICE"

    click_on("Francis FACTICE")

    expect(page).to have_content(:adsf)
  end
end
