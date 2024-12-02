RSpec.describe "Prise de rdv avec sectorisations pour deux territoires dans le même département" do
  let!(:territory_medico_social) { create(:territory, name: "Drome social", departement_number: "26") }
  let!(:territory_insertion) { create(:territory, name: "Drome insertion", departement_number: "26") }

  let!(:orga_social) { create(:organisation, territory: territory_medico_social) }
  let!(:orga_insertion) { create(:organisation, territory: territory_insertion) }

  let!(:service) { create(:service, name: "RSA") }
  let!(:motif_social) { create(:motif, name: "Rdv d'orientation", organisation: orga_social, service: service) }
  let!(:motif_insertion) { create(:motif, name: "Rdv d'orientation", organisation: orga_insertion, service: service) }

  let!(:lieu_social) { create(:lieu, name: "CMS Valence", organisation: orga_social) }
  let!(:lieu_insertion) { create(:lieu, name: "Pole Emploi Valence", organisation: orga_insertion) }

  before do
    create(:plage_ouverture, :weekdays, first_day: 8.days.from_now, motifs: [motif_social], lieu: lieu_social, organisation: orga_social)
    create(:plage_ouverture, :weekdays, first_day: 8.days.from_now, motifs: [motif_insertion], lieu: lieu_insertion, organisation: orga_insertion)
  end

  it "allows two territories in the same departement to use sectorisation and shows the organisations alongside one another", js: true do
    social_sector = Sector.create!(territory: territory_medico_social, name: "Valence", human_id: "valence")
    insertion_sector = Sector.create!(territory: territory_insertion, name: "Valence", human_id: "valence")

    Zone.create!(level: Zone::LEVEL_CITY, city_name: "Valence", city_code: 26362, sector: social_sector)
    Zone.create!(level: Zone::LEVEL_CITY, city_name: "Valence", city_code: 26362, sector: insertion_sector)

    SectorAttribution.create!(sector: social_sector, organisation: orga_social, level: SectorAttribution::LEVEL_ORGANISATION)
    SectorAttribution.create!(sector: insertion_sector, organisation: orga_insertion, level: SectorAttribution::LEVEL_ORGANISATION)

    visit root_path
    fill_in("search_where", with: "9 Rue Georges Méliès, 26000 Valence")

    # Fake autocomplete
    page.execute_script("document.querySelector('#search_departement').value = '26'")
    page.execute_script("document.querySelector('#search_submit').disabled = false")

    click_button("Rechercher")
    click_on("Rdv d'orientation") # sélection du motif
    expect(page).to have_content "2 lieux sont disponibles"
    expect(page).to have_content("CMS Valence")
    expect(page).to have_content("Pole Emploi Valence")
  end
end
