# frozen_string_literal: true

require "csv"

API_ENDPOINT = "https://api-adresse.data.gouv.fr/search/csv/"

def update_user_city_name_from(geocoded_addresses)
  puts geocoded_addresses.inspect
  puts "#{geocoded_addresses.length} ville(s) d'usager à mettre à jour"
  geocoded_addresses.each do |city_data|
    User.find(city_data["id"]).update_columns(
      post_code: city_data["result_postcode"],
      city_code: city_data["result_citycode"],
      city_name: city_data["result_cityname"]
    )
  end
end

def geocode(file)
  response = Typhoeus.post(
    API_ENDPOINT,
    method: :post,
    body: {
      data: File.new(file),
      result_columns: "id,result_city,result_postcode,result_citycode",
    }
  )
  CSV.parse(response.body, headers: true).map(&:to_h)
end

def addresses_in_csv
  file = Tempfile.create("bla.csv")
  CSV.open(file, "wb") do |csv|
    csv << %w[id adresse]
    User.where.not(address: [nil, ""]).where(city_name: [nil, ""]).in_batches(of: 500).each_with_index do |users, index|
      Rails.logger.info("Récupère l'ensemble d'utilisateurs du batch #{index}")
      users.map { |u| [u.id, u.address] }.each { |ia| csv << ia }
    end
  end
  file
end

puts "mise à jour du nom de ville de l'usager à partir de son adresse"
puts ""

update_user_city_name_from geocode addresses_in_csv

puts "Terminé"
