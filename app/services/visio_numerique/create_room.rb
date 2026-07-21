module VisioNumerique
  class CreateRoom
    class ApiError < StandardError; end
    class NotConfiguredError < StandardError; end

    def initialize(access_token:)
      @access_token = access_token
    end

    def self.configured?
      ENV["VISIO_NUMERIQUE_API_URL"].present?
    end

    def call
      raise NotConfiguredError, "VISIO_NUMERIQUE_API_URL n'est pas configuré" unless self.class.configured?

      response = Typhoeus.post(
        "#{ENV['VISIO_NUMERIQUE_API_URL']}/rooms/",
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
