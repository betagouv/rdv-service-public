module VisioNumerique
  class CreateRoom
    class ApiError < StandardError; end

    DEFAULT_API_URL = "https://visio.numerique.gouv.fr/external-api/v1.0".freeze

    def initialize(access_token:)
      @access_token = access_token
    end

    def call
      response = connection.post("rooms/") do |req|
        req.headers["Authorization"] = "Bearer #{@access_token}"
      end

      raise ApiError, "HTTP #{response.status}: #{response.body}" unless response.success?

      response.body
    end

    private

    def connection
      Faraday.new("#{api_url}/") do |f|
        f.request :json
        f.response :json
        f.options.timeout = 5
        f.options.open_timeout = 2
      end
    end

    def api_url
      ENV.fetch("VISIO_NUMERIQUE_API_URL", DEFAULT_API_URL)
    end
  end
end
