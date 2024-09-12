RSpec.describe "Agent can setup sectorisation", type: :feature do
  let(:territory) { create(:territory, departement_number: "26") }
  let!(:service) { create(:service, name: "Service social") }
  let(:ccas_valentinois) { create(:organisation, territory: territory, name: "CCAS Valentinois") }
  let(:mds_drome) { create(:organisation, territory: territory, name: "MDS Drôme") }
  let(:lea) { create(:agent, first_name: "lea", last_name: "Dupont", services: [service], role_in_territories: [territory], admin_role_in_organisations: [ccas_valentinois, mds_drome]) }
  let!(:marguerite) { create(:agent, first_name: "Marguerite", last_name: "Duras", services: [service], role_in_territories: [territory], basic_role_in_organisations: [ccas_valentinois, mds_drome]) }

  before { login_as(lea, scope: :agent) }

  it "works", :js do
    visit admin_territory_sectorization_path(territory)
    find("a", text: "Secteurs").click
    click_on "Créer un nouveau secteur"
    fill_in :sector_name, with: "Secteur Nord"
    fill_in :sector_human_id, with: "nord"
    click_on "Enregistrer"
    click_on "Ajouter une commune ou une rue"
    fill_in_readonly_input("#zone_city_name", "Valence")
    fill_in_readonly_input("#zone_city_code", "26362")
    click_on "Enregistrer"
    click_on "Attribuer une organisation ou un agent"
    select "MDS Drôme", from: "Organisation"
    click_on "Ajouter"
    expect(page).to have_content("Attribution ajoutée")

    click_on "Secteurs"
    click_on "Créer un nouveau secteur"
    fill_in :sector_name, with: "Secteur Sud"
    fill_in :sector_human_id, with: "sud"
    click_on "Enregistrer"
    click_on "Ajouter une commune ou une rue"
    fill_in_readonly_input("#zone_city_name", "Albon")
    fill_in_readonly_input("#zone_city_code", "26004")
    click_on "Enregistrer"
    click_on "Attribuer une organisation ou un agent"
    choose "Agent désigné"
    select "MDS Drôme", from: "Organisation"
    select "DURAS Marguerite (Service social)", from: "Agent"
    click_on "Ajouter"
    expect(page).to have_content("Attribution ajoutée")
  end
end
