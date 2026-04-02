class GeoCoding
  def find_geo_coordinates(address)
    address_api_response(address).dig("features", 0, "geometry", "coordinates")
  end

  def get_geolocation_results(address, departement_number = nil)
    feature = first_matching_feature(address, departement_number)
    return nil unless feature

    {
      city_code: feature.dig("properties", "citycode"),
      post_code: feature.dig("properties", "postcode"),
      city_name: feature.dig("properties", "city"),
      # 5 chars for city insee code, 1 for _, 4 (or more) for street fantoir
      street_ban_id: feature.dig("properties", "id").split("_").first(2).join("_"),
    }
  end

  private

  def first_matching_feature(address, departement_number = nil)
    features = address_api_response(address)&.dig("features")
    return nil unless features

    if departement_number
      select_feature_by_department(features, departement_number) || features.first
    else
      features.first
    end
  end

  def select_feature_by_department(features, departement_number)
    features.find { |f| f["properties"]["context"].downcase.include?(departement_number) }
  end

  def address_api_response(address)
    address_api_response = Rails.cache.fetch("api-adresse:#{address}") do
      Faraday.get("https://data.geopf.fr/geocodage/search/", q: address)
    end

    JSON.parse(address_api_response.body)
  end
end
