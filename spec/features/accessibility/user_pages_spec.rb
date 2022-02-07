# frozen_string_literal: true

def expect_page_to_be_axe_clean(path)
  visit path
  expect(page).to have_current_path(path)
  expect(page).to be_axe_clean
end

describe "welcome", js: true do
  it "root path page is accessible" do
    expect_page_to_be_axe_clean(root_path)
  end

  it "accueil_mds_path page is accessible" do
    expect_page_to_be_axe_clean(accueil_mds_path)
  end

  it "accessibility_path page is accessible" do
    expect_page_to_be_axe_clean(accessibility_path)
  end

  it "lieux_path page is accessible" do
    territory = create(:territory, departement_number: "75")
    organisation = create(:organisation, territory: territory)
    lieu = create(:lieu, organisation: organisation)
    service = create(:service)
    motif = create(:motif, service: service, organisation: organisation)
    create(:plage_ouverture, motifs: [motif], lieu: lieu)

    path = lieux_path(search: {
                        city_code: 75_119,
                        departement: 75,
                        latitude: 48.887148,
                        longitude: 2.38748,
                        motif_name_with_location_type: motif.name_with_location_type,
                        service: service.id,
                        street_ban_id: "75119_4903",
                        where: "152 Avenue Jean Jaurès Paris 75019 Paris 19e Arrondissement 75 Paris Île-de-France"
                      })
    expect_page_to_be_axe_clean(path)
  end

  it "mds_path page is accessible" do
    visit mds_path
    expect(page).to be_axe_clean
  end

  it "contact_path page is accessible" do
    visit contact_path
    expect(page).to be_axe_clean
  end
end
