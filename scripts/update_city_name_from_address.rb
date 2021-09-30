# frozen_string_literal: true

require "csv"

API_ENDPOINT = "https://api-adresse.data.gouv.fr/search/csv/"

def update_user_city_name_from(geocoded_addresses)
  puts "#{geocoded_addresses.length} ville(s) d'usager à mettre à jour"
  geocoded_addresses.each do |id, data|
    User.find(id).update_columns(
      city_name: data[:address],
      post_code: data[:postal_code],
      city_code: data[:city_code]
    )
  end
end

def geocode(file)
  response = Typhoeus.post(
    API_ENDPOINT,
    method: :post,
    body: { data: File.new(file) }
  )
  geocoded_addresses = {}

  CSV.parse(response.body) do |line|
    next if line[0] == "id"

    geocoded_addresses[line[0]] = {
      city_name: line[12],
      post_code: line[11],
      city_code: line[14]
    }
  end
  puts geocoded_addresses.length
  geocoded_addresses
end

def addresses_in_csv
  file = Tempfile.create("bla.csv")
  CSV.open(file, "wb") do |csv|
    csv << %w[id adresse]
    User.where.not(address: [nil, ""]).where(city_name: [nil, ""]).pluck(:id, :address).each do |id, address|
      csv << [id, address]
    end
  end
  file
end

puts "mise à jour du nom de ville de l'usager à partir de son adresse"
puts ""

update_user_city_name_from geocode addresses_in_csv

puts "Terminé"
