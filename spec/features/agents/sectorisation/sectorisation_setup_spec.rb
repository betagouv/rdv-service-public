RSpec.describe "Agent can setup sectorisation", type: :feature do
  let(:territory) { create(:territory, departement_number: "26") }
  let(:ccas_valentinois) { create(:organisation, territory: territory, name: "CCAS Valentinois") }
  let(:mds_drome) { create(:organisation, territory: territory, name: "MDS Drôme") }
  let(:agent) { create(:agent, role_in_territories: [territory], admin_role_in_organisations: [ccas_valentinois, mds_drome]) }

  before { login_as(agent, scope: :agent) }

  it "works" do
    visit admin_territory_sectorization_path(territory)
    find("h2", text: "Secteurs").find(:xpath, "..").click
    sleep 1
    click_on "Créer un nouveau secteur"
    fill_in :sector_name, with: "Secteur Nord"
    fill_in :sector_human_id, with: "nord"
    click_on "Enregistrer"
    click_on "Ajouter une commune ou une rue"
    sleep 1
    find("#zone_city_name").native["value"] = "Valence"
    find("#zone_city_code").native["value"] = "26362"
    click_on "Enregistrer"
    click_on "Attribuer une organisation ou un agent"
    select "MDS Drôme", from: "Organisation"
    click_on "Ajouter"
  end
end
