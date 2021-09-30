# frozen_string_literal: true

require "csv"

API_ENDPOINT = "https://api-adresse.data.gouv.fr/search/csv/"

def update_user_city_name_from(geocoded_addresses)
  puts "#{geocoded_addresses.length} ville(s) d'usager à mettre à jour"
  User.update(geocoded_addresses.keys, geocoded_addresses.values)
end

def geocode(file)
  response = Typhoeus.post(
    API_ENDPOINT,
    method: :post,
    body: { data: File.new(file) }
  )
  result_lines = CSV.parse(response.body)[1..]
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
