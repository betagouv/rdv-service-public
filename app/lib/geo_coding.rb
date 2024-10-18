class GeoCoding
  def find_geo_coordinates(address)
    address_api_response(address).dig("features", 0, "geometry", "coordinates")
  end

  def get_geolocation_results(address, departement_number)
    feature = get_first_feature(address, departement_number)
    return nil unless feature

    {
      city_code: feature.dig("properties", "citycode"),
      # 5 chars for city insee code, 1 for _, 4 for street fantoir
      street_ban_id: feature.dig("properties", "id").first(10),
    }
  end

  private

  def get_first_feature(address, departement_number)
    features = address_api_response(address)&.dig("features")
    return nil unless features

    select_feature_by_department(features, departement_number) || features.first
  end

  def select_feature_by_department(features, departement_number)
    # we take the first feature that has the right departement number
    features.find { |f| f["properties"]["context"].downcase.include?(departement_number) }
  end

  def address_api_response(address)
    address_api_response = Rails.cache.fetch("api-adresse:#{address}") do
      Faraday.get("https://api-adresse.data.gouv.fr/search/", q: address)
    end

    JSON.parse(address_api_response.body)
  end
end
