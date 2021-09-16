# frozen_string_literal: true

require "csv"
require "rest-client"

API_ENDPOINT = "https://api-adresse.data.gouv.fr/search/csv/"

def update_user_city_name_from(geocoded_addresses)
  puts "#{geocoded_addresses.length} ville(s) d'usager à mettre à jour"
  geocoded_addresses.each do |id, ville|
    User.find(id).update(city_name: ville)
  end
end

def geocode(file)
  response = RestClient.post(API_ENDPOINT, { data: File.new(file) })

  result_lines = CSV.parse(response.body, encoding: response.encoding)[1..]

  geocoded_addresses = {}
  result_lines.each do |line|
    id = line[0]
    address = line[12]
    geocoded_addresses[id] = address
  end
  geocoded_addresses
end

def addresses_in_csv
  file = Tempfile.create("bla.csv")
  CSV.open(file, "wb") do |csv|
    csv << %w[nom adresse]
    User.all.each do |user|
      next if user.address.blank?

      csv << [user.id, user.address]
    end
  end
  file
end

puts "mise à jour du nom de vile de l'usager à partir de son adresse"
puts ""

update_user_city_name_from geocode addresses_in_csv

puts "Terminé"
