class GeoCoding
  # Score de pertinence renvoyé par la BAN (entre 0 et 1) au-delà duquel un résultat unique est retenu sans demander de confirmation
  AUTO_SELECT_MIN_SCORE = 0.8

  AddressResult = Data.define(:label, :score, :departement, :city_code, :street_ban_id, :latitude, :longitude) do
    def search_params
      { address: label, departement:, city_code:, street_ban_id:, latitude:, longitude: }
    end
  end

  def find_geo_coordinates(address)
    address_api_response(address)&.dig("features", 0, "geometry", "coordinates")
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

  # Renvoie nil si l'API est indisponible, et un tableau vide si aucune adresse ne correspond
  def search_addresses(query, limit: 5)
    features = address_api_response(query, limit:)&.dig("features")
    return nil unless features

    features.map { address_result(it) }
  end

  def self.auto_selectable_result(results)
    high_score_results = results.to_a.select { it.score >= AUTO_SELECT_MIN_SCORE }
    high_score_results.first if high_score_results.one?
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

  def address_result(feature)
    properties = feature["properties"]
    longitude, latitude = feature.dig("geometry", "coordinates")

    AddressResult.new(
      label: address_label(properties),
      score: properties["score"].to_f,
      departement: properties["context"].split(",").first,
      city_code: properties["citycode"],
      street_ban_id: street_ban_id(properties),
      latitude:,
      longitude:
    )
  end

  # ex : « 52 Avenue Jean Jaurès, Paris, 75019 », ou « Paris, 75019 » pour une commune
  def address_label(properties)
    details = [properties["postcode"]]
    details.unshift(properties["city"]) if properties["name"] != properties["city"]
    [properties["name"], *details].compact_blank.join(", ")
  end

  def street_ban_id(properties)
    case properties["type"]
    when "street"
      properties["id"]
    when "housenumber"
      # 5 caractères pour le code insee de la commune, 1 pour _, 4 (ou plus) pour le code fantoir de la voie
      properties["id"].split("_").first(2).join("_")
    end
  end

  def address_api_response(address, limit: nil)
    query_params = { q: address, limit: }.compact

    Rails.cache.fetch("api-adresse:#{query_params.values.join(':')}", skip_nil: true) do
      response = Faraday.new(request: { timeout: 3 }).get("https://data.geopf.fr/geocodage/search/", query_params)
      JSON.parse(response.body) if response.success?
    end
  rescue JSON::ParserError, Faraday::Error => e
    Sentry.capture_exception(e)
    nil
  end
end
