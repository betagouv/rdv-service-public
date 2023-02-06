# frozen_string_literal: true

describe "Allocation For Search Context" do
  it "stay under 5500" do
    departement_number = "75"
    address = "20 avenue de Ségur 75007 Paris"
    city_code = "75007"

    organisation = create(:organisation)
    rsa_orientation = create(:motif_category, name: "RSA orientation sur site", short_name: "rsa_orientation")
    motif = create(:motif, name: "RSA orientation sur site", motif_category: rsa_orientation, organisation: organisation)

    create_list(:plage_ouverture, 300, lieu: create(:lieu), motifs: [motif])
    lieu = create(:lieu, organisation: organisation)

    geo_search = instance_double(Users::GeoSearch, available_motifs: Motif.where(id: motif.id))
    allow(Users::GeoSearch).to receive(:new)
      .with(departement: departement_number, city_code: city_code, street_ban_id: nil)
      .and_return(geo_search)
    create(:plage_ouverture, lieu: lieu, motifs: [motif], first_day: 1.day.from_now, organisation: organisation)

    params = { address: address, departement: departement_number, city_code: city_code, lieu_id: lieu.id, motif_name_with_location_type: "#{motif.name}-#{motif.location_type}" }

    search_context = SearchContext.new(nil, params)

    before = GC.stat[:total_allocated_objects]
    search_context.unique_motifs_by_name_and_location_type
    after = GC.stat[:total_allocated_objects]
    # Le chiffre est baser sur l'expérimentation.
    # Sur l'ancienne façon de faire le filtre sur les lieux, nous avons
    # 3342 allocations, avec la nouvelle 2166.
    #
    # Edit du 18 octobre.
    # La recherche de RDV collectif lié au lieu ajoute
    # pas mal d'allocations...
    expect(after - before).to be <= 5500
  end
end
