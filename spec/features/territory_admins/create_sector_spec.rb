RSpec.describe "territory admin can manage sectors" do
  let(:territory) { create(:territory, departement_number: "62") }
  let(:agent) do
    create(:agent, role_in_territories: [territory])
  end
  let!(:sector_arques) { create(:sector, human_id: "arques", territory: territory) }

  before do
    create(:agent_territorial_access_right, agent: agent, territory: territory)
    login_as(agent, scope: :agent)
    visit admin_territory_path(id: territory.id)
  end

  it "allows creation" do
    click_on "Sectorisation"
    click_on "Secteurs"
    expect(page).to have_content "Secteurs"
    click_on "Créer un nouveau secteur"
    fill_in("Nom", with: "Secteur 2")
    fill_in("Identifiant", with: "secteur-2")
    click_on "Enregistrer"
    expect(page).to have_content "Nom: Secteur 2"
  end
end
