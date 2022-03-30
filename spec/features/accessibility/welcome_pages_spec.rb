# frozen_string_literal: true

describe "welcome pages", js: true do
  it "contact_path page is accessible" do
    expect_page_to_be_axe_clean(contact_path)
  end
  
  it "accueil_mds_path page is accessible" do
    expect_page_to_be_axe_clean(accueil_mds_path)
  end

  it "mds_path page is accessible" do
    expect_page_to_be_axe_clean(mds_path)
  end

  it "prendre rdv is accessible" do
    territory = create(:territory, departement_number: "75")
    service = create(:service)
    organisation = create(:organisation, territory: territory)
    motif = create(:motif, service: service, organisation: organisation, reservable_online: true)
    lieu = create(:lieu, organisation: organisation)
    create(:plage_ouverture, motifs: [motif], lieu: lieu)

    path = prendre_rdv_path(city_code: "75_119",
                            departement: "75",
                            latitude: "48.887148",
                            longitude: "2.38748",
                            street_ban_id: "75119_4903",
                            address: "152 Avenue Jean Jaurès Paris 75019 Paris")
    expect_page_to_be_axe_clean(path)
  end

  it "new_organisation is accessible" do
    expect_page_to_be_axe_clean(new_organisation_path)
  end
  
  it "root path page is accessible" do
    expect_page_to_be_axe_clean(root_path)
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
end
