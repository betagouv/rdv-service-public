# frozen_string_literal: true

describe "accueil_mds", js: true do
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
end
