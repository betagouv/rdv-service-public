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

      connection = Faraday.new("#{ENV['VISIO_NUMERIQUE_API_URL']}/") do |f|
        f.request :json
        f.response :json
      end

      response = connection.post("rooms/") do |req|
        req.headers["Authorization"] = "Bearer #{@access_token}"
      end

      raise ApiError, "HTTP #{response.status}: #{response.body}" unless response.success?

      response.body
    end
  end
end
