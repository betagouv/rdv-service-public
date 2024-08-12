RSpec.describe "Creating a new account for a mairie", :js do
  let(:super_admin) { create :super_admin }
  let!(:cni_motif_category) { create(:motif_category, name: Api::Ants::EditorController::CNI_MOTIF_CATEGORY_NAME) }
  let!(:passport_motif_category) { create(:motif_category, name: Api::Ants::EditorController::PASSPORT_MOTIF_CATEGORY_NAME) }
  let!(:cni_passport_motif_category) { create(:motif_category, name: Api::Ants::EditorController::CNI_AND_PASSPORT_MOTIF_CATEGORY_NAME) }
  let!(:territory) { create(:territory, :mairies) }
  let!(:service) { create(:service, name: "Mairie") }

  let(:autocomplete_response) do
    <<~JSON
      {"type":"FeatureCollection","version":"draft","features":[{"type":"Feature","geometry":{"type":"Point","coordinates":[2.429639,48.880505]},"properties":{"label":"Rue de Romainville 93230 Romainville","score":0.51,"id":"93063_8160","name":"Rue de Romainville","postcode":"93230","citycode":"93063","x":658170.04,"y":6864649.51,"city":"Romainville","context":"93, Seine-Saint-Denis, Île-de-France","type":"street","importance":0.58716,"street":"Rue de Romainville"}}],"attribution":"BAN","licence":"ETALAB-2.0","query":"Place de la mairie, Romainville, 93230","limit":5}
    JSON
  end

  before { login_as(super_admin, scope: :super_admin) }

  it "creates a new organisation" do
    visit super_admins_mairie_comptes_path
    click_link "Création mairie compte"

    fill_in("Nom", with: "Mairie de Romainville")

    stub_request(:get, "https://api-adresse.data.gouv.fr/search/?q=Place%20de%20la%20mairie,%20Romainville,%2093230")
      .to_return(status: 200, body: autocomplete_response, headers: {})
    fill_in("Adresse", with: "Place de la mairie, Romainville, 93230")
    fill_in("Agent first name", with: "Francis")
    fill_in("Agent last name", with: "Factice")
    fill_in("Agent email", with: "francis@factice.org")

    click_button("Enregistrer")
    expect(page).to have_content("Mairie compte a été correctement créé(e).")
    expect(Organisation.count).to eq(1)
  end
end
