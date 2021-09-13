# frozen_string_literal: true

User.all.each do |user|
  next if user.address.blank?

  response = Net::HTTP.get_response(URI("https://api-adresse.data.gouv.fr/search/?q=#{URI.encode(user.address.to_s)}"))

  response_json = JSON.parse(response.body)
  best_response = response_json["features"].sort_by { |r| r["properties"]["score"] }.reverse.first
  next if best_response.blank?

  city_code = best_response["properties"]["citycode"]
  post_code = best_response["properties"]["postcode"]
  city_name = best_response["properties"]["city"]

  user.update(city_code: city_code, post_code: post_code, city_name: city_name)
end
