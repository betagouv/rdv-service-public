RSpec.describe "Gestion des webhooks par les admins de territoires" do
  let(:territory) { create(:territory, departement_number: "62") }
  let(:organisation) { create(:organisation, territory: territory, name: "MDS Paris Nord") }
  let(:agent) { create(:agent, admin_role_in_organisations: [organisation], role_in_territories: [territory]) }

  before { login_as(agent, scope: :agent) }

  it "allows full webhook lifecycle" do
    visit admin_territory_webhook_endpoints_path(territory)

    click_on "Ajouter"

    select "MDS Paris Nord", from: "Organisation"
    fill_in "URL de destination", with: "https://example.com"
    fill_in "Clé privée", with: "fausse_clé_privée_de_test"
    find("label", text: "Usager").click

    click_on "Enregistrer"

    expect(organisation.webhook_endpoints.count).to eq(1)

    visit edit_admin_territory_webhook_endpoint_path(territory, organisation.webhook_endpoints.reload.first.id)

    fill_in "URL de destination", with: "https://new_url.com"

    click_on "Enregistrer"

    expect(page).to have_content "https://new_url.com"
    expect(organisation.webhook_endpoints.last.reload.target_url).to eq("https://new_url.com")
  end
end
