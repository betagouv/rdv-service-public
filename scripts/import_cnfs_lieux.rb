# frozen_string_literal: true

class LieuImporter
  def initialize(permanence)
    @permanence = OpenStruct.new(permanence)
  end

  def import_not_needed
    no_organisation? || organisation_already_configured ||
      found_matching_lieu || found_matching_coordinates
  end

  def no_organisation?
    @organisation.blank?
  end

  def organisation_already_configured
    organisation.lieux.count >= 2
  end

  def found_matching_coordinates
    longitude, latitude = coordinates

    organisation.lieux.find do |l|
      l.latitude == latitude && l.longitude == longitude
    end.any?
  end

  def create!
    longitude, latitude = coordinates

    Lieu.create(
      name: organisation.name,
      organisation: organisation,
      latitude: latitude,
      longitude: longitude,
      address: @structure.address,
      availability: :enabled
    )
  end

  def coordinates
    adresse_api_response.dig("features", 0, "geometry", "coordinates")
  end

  def city_name
    adresse_api_response.dig("features", 0, "properties", "city")
  end

  def adresse_api_response
    zipcode_regex = /\d{5}/
    zipcode = @structure.address[zipcode_regex]

    @adresse_api_response ||= Faraday.get(
      "https://api-adresse.data.gouv.fr/search/",
      q: @structure.address,
      postcode: zipcode
    )
    JSON.parse(@adresse_api_response.body)
  end

  private

  def full_address
    "#{permanence.address}, #{}"
  end

  def coordinates
    adresse_api_response.dig("features", 0, "geometry", "coordinates")
  end

  def organisation
    @organisation ||= Organisation.find_by(external_id: @permanence.structureId)
  end

  def adresse_api_response
    zipcode_regex = /\d{5}/
    zipcode = @permanence.address[zipcode_regex]

    @adresse_api_response ||= Faraday.get(
      "https://api-adresse.data.gouv.fr/search/",
      q: @permanence.address,
      postcode: zipcode
    )
    JSON.parse(@adresse_api_response.body)
  end
end

ActiveRecord::Base.logger = nil
# permanences = JSON.load_file("/tmp/uploads/permanences.json")
permanences = JSON.load_file("tmp/permanences.json")

ActiveRecord::Base.transaction do
  permanences.each do |permanence|
    next unless organisation

    # Ne pas importer des nouveaux lieux si ils ont déjà été configurés manuellement
    next if

    matching_lieu = organisation.lieux.find do |lieu|
      lieu.address.downcase.gsub(/[^0-9a-z]/, "").start_with?(permanence["adresse"].downcase.gsub(/[^0-9a-z]/, ""))
    end

    # Ne pas importer le lieu de permanence s'il existe déjà
    next if matching_lieu

    addresse =
      puts "Nouveau lieu potentiel pour #{organisation.name} :"
    puts "adresse de permanence #{permanence['adresse']}"
    puts "adresses de lieux #{organisation.lieux.map(&:address)}"
  end
end
