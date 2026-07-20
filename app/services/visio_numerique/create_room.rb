module VisioNumerique
  class CreateRoom
    API_BASE_URL = "https://visio-sandbox.beta.numerique.gouv.fr/external-api/v1.0".freeze

    class ApiError < StandardError; end

    def initialize(access_token:)
      @access_token = access_token
    end

    def call
      response = Typhoeus.post(
        "#{API_BASE_URL}/rooms/",
        headers: {
          "Authorization" => "Bearer #{@access_token}",
          "Content-Type" => "application/json",
        },
        body: {}.to_json
      )

      raise ApiError, "HTTP #{response.response_code}: #{response.response_body}" unless response.success?

      JSON.parse(response.body)
    end
  end
end
