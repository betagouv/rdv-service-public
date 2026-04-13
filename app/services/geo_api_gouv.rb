class GeoApiGouv
  def initialize(code_insee)
    @code_insee = code_insee
  end

  def population
    parsed_response&.fetch("population", nil)
  rescue StandardError => e
    Sentry.capture_exception(e)
    nil
  end

  private

  def parsed_response
    @parsed_response ||= JSON.parse(response.body)
  rescue StandardError => e
    Sentry.capture_exception(e)
    nil
  end

  def response
    @response ||= Faraday.get("https://geo.api.gouv.fr/communes/#{@code_insee}?fields=population")
  end
end
