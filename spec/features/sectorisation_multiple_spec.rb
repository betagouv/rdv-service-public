describe "Sectorisation et prise de rdv pour deux territoires dans le même département" do
  let!(:territory_medico_social) { create(:territory, name: "Drome social", departement_number: "26") }
  let!(:territory_insertion) { create(:territory, name: "Drome insertion", departement_number: "26") }

  let!(:admin_medico_social) do
    create(:agent).tap do |agent|
      create(:agent_territorial_access_right, agent: agent, territory: territory_medico_social)
    end
  end

  let!(:admin_insertion) do
    create(:agent).tap do |agent|
      create(:agent_territorial_access_right, agent: agent, territory: territory_insertion)
    end
  end

  let!(:orga_social) { create(:organisation, territory: territory_medico_social) }
  let!(:orga_insertion) { create(:organisation, territory: territory_insertion) }

  it "allows two territories in the same departement to use sectorisation" do
    social_sector = Sector.create!(territory: territory_medico_social, name: "Valence", human_id: "valence")
    insertion_sector = Sector.create!(territory: territory_insertion, name: "Valence", human_id: "valence")

    Zone.create!(level: Zone::LEVEL_CITY, city_name: "Valence", city_code: 26362, sector: social_sector)
    Zone.create!(level: Zone::LEVEL_CITY, city_name: "Valence", city_code: 26362, sector: insertion_sector)

    SectorAttribution.create!(sector: social_sector, organisation: orga_social, level: SectorAttribution::LEVEL_ORGANISATION)
    SectorAttribution.create!(sector: insertion_sector, organisation: orga_insertion, level: SectorAttribution::LEVEL_ORGANISATION)

    # login_as(admin_medico_social, scope: :agent)
    # visit new_admin_territory_sector_path(territory_id: territory_medico_social.id)
    # fill_in "Nom", with: "Valence"
    # fill_in "Identifiant", with: "valence-social"
    # click_on "Enregistrer"
    #
    # click_on "Ajouter une commune ou une rue"
    # fill_in "Nom de la commune", with: "Valence"
    # fill_in "Code commune INSEE", with: 26362
    #
    # click_on "Enregistrer"
  end
end
