# frozen_string_literal: true

module GeoCoding
  def find_geo_coordinates(address)
    address_api_response(address).dig("features", 0, "geometry", "coordinates")
  end

  private

  def address_api_response(address)
    address_api_response = Rails.cache.fetch("api-adresse:#{address}") do
      Faraday.get("https://api-adresse.data.gouv.fr/search/", q: address)
    end

    JSON.parse(address_api_response.body)
  end
end
