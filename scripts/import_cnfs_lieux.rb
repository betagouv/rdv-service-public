# frozen_string_literal: true

# Usage : download locally the list of permanences in tmp/permanences.json then run :
# scalingo --app production-rdv-solidarites  --region osc-secnum-fr1  run --file tmp/permanences.json "rails runner scripts/import_cnfs_lieux.rb"

class LieuImporter
  def initialize(permanence)
    @permanence = OpenStruct.new(permanence)
  end

  def import_not_needed?
    no_organisation? || found_matching_lieu || found_matching_coordinates
  end

  def create
    longitude, latitude = coordinates

    Lieu.create(
      name: @permanence.nom,
      organisation: organisation,
      latitude: latitude,
      longitude: longitude,
      address: full_address,
      availability: :enabled
    )
  end

  private

  def no_organisation?
    organisation.blank?
  end

  def found_matching_lieu
    organisation.lieux.find do |lieu|
      lieu.address.downcase.gsub(/[^0-9a-z]/, "").start_with?(
        @permanence.adresse.downcase.gsub(/[^0-9a-z]/, "")
      )
    end
  end

  def found_matching_coordinates
    longitude, latitude = coordinates

    organisation.lieux.find do |l|
      l.latitude == latitude && l.longitude == longitude
    end
  end

  def coordinates
    adresse_api_response.dig("features", 0, "geometry", "coordinates")
  end

  def adresse_api_response
    @adresse_api_response ||= Rails.cache.fetch("api-adresse:#{full_address}:#{@permanence.code_postal}") do
      Faraday.get(
        "https://api-adresse.data.gouv.fr/search/",
        q: full_address,
        postcode: @permanence.code_postal
      )
    end
    JSON.parse(@adresse_api_response.body)
  end

  def full_address
    "#{@permanence.adresse}, #{@permanence.commune} #{@permanence.code_postal}"
  end

  def organisation
    @organisation ||= Organisation.find_by(external_id: @permanence.structureId)
  end
end

permanences = JSON.load_file("/tmp/uploads/permanences.json")

lieux_count = Lieu.count

permanences.each do |permanence|
  importer = LieuImporter.new(permanence)

  if importer.import_not_needed?
    puts "noop for #{permanence}"
  else
    puts "creating for #{permanence}"
    importer.create
  end
end
puts "done !"
puts "#{Lieu.count - lieux_count} lieux created"
