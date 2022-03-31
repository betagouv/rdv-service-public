# frozen_string_literal: true

require "csv"

def geocode(street_address, zipcode)
  response = Faraday.get(
    "https://api-adresse.data.gouv.fr/search/",
    q: street_address,
    postcode: zipcode
  )
  response_hash = JSON.parse(response.body)
  response_hash.dig("features", 0, "geometry", "coordinates")
end

conseillers_numeriques = CSV.read("/tmp/uploads/export-cnfs.csv", headers: true, col_sep: ";")

conseiller_numerique_service = Service.find_by(name: "Conseiller Numérique")
cnfs_territory = Territory.find_by(name: "Conseillers Numériques")

conseillers_numeriques.each do |conseiller_numerique|
  ActiveRecord::Base.transaction do
    organisation = Organisation.find_or_create_by(
      name: conseiller_numerique["Nom de la structure"],
      territory: cnfs_territory
    )

    if organisation.motifs.none?
      Motif.create!(
        name: "Accompagnement individuel",
        color: "#99CC99",
        default_duration_in_min: 60,
        location_type: :public_office,
        organisation: organisation,
        service: conseiller_numerique_service
      )

      Motif.create!(
        name: "Atelier collectif",
        color: "#4A86E8",
        default_duration_in_min: 120,
        location_type: :public_office,
        collectif: true,
        organisation: organisation,
        service: conseiller_numerique_service
      )
    end

    if organisation.lieux.none?
      zipcode_regex = /\d{5}/
      zipcode = conseiller_numerique["Adresse de la structure"][zipcode_regex]
      longitude, latitude = geocode(conseiller_numerique["Adresse de la structure"], zipcode)

      Lieu.create!(
        name: conseiller_numerique["Nom de la structure"],
        organisation: organisation,
        latitude: latitude,
        longitude: longitude,
        address: conseiller_numerique["Adresse de la structure"],
        availability: :enabled
      )
    end

    Agent.invite!(
      email: conseiller_numerique["Email @conseiller-numerique.fr"],
      first_name: conseiller_numerique["Prénom"].capitalize,
      last_name: conseiller_numerique["Nom"],
      service: conseiller_numerique_service,
      password: SecureRandom.hex,
      roles_attributes: [{ organisation: organisation, level: AgentRole::LEVEL_ADMIN }]
    )
  end
  puts "Import réussi pour #{conseiller_numerique['Email @conseiller-numerique.fr']}"
end
