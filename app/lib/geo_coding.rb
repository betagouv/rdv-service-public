class GeoCoding
  def find_geo_coordinates(address)
    address_api_response(address).dig("features", 0, "geometry", "coordinates")
  end

  def get_geolocation_results(address, departement_number)
    feature = get_first_feature(address, departement_number)
    return nil unless feature

    {
      city_code: feature.dig("properties", "citycode"),
      # 5 chars for city insee code, 1 for _, 4 (or more) for street fantoir
      street_ban_id: feature.dig("properties", "id").split("_").first(2).join("_"),
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
    cleaned_address = clean_address(address)
    return nil if cleaned_address.blank?

    response = Rails.cache.fetch("api-adresse:#{cleaned_address}") do
      Faraday.get("https://data.geopf.fr/geocodage/search/", q: cleaned_address)
    end

    JSON.parse(response.body)
  end

  # L'API IGN refuse les requêtes qui ne commencent pas par un caractère alphanumérique.
  # On retire donc tous les caractères non-alphanumériques en début d'adresse.
  def clean_address(address)
    address&.gsub(/\A[^\p{Alnum}]+/, "")&.strip
  end
end
