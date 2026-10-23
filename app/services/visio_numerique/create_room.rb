module VisioNumerique
  class CreateRoom
    class ApiError < StandardError; end

    DEFAULT_API_URL = "https://visio.numerique.gouv.fr/external-api/v1.0".freeze

    # L'access token ProConnect n'est disponible que lorsque l'agent vient de se connecter
    def initialize(agent:, pro_connect_access_token: nil)
      @agent = agent
      @pro_connect_access_token = pro_connect_access_token
    end

    def visio_url
      return if token.blank?

      response = connection.post("rooms/") do |req|
        req.headers["Authorization"] = "Bearer #{token}"
      end

      raise ApiError, "HTTP #{response.status}: #{response.body}" unless response.success?

      response.body.fetch("url")
    rescue VisioNumerique::CreateRoom::ApiError => e
      Rails.logger.error("Visio Numerique API error: #{e.message}")
      Sentry.capture_exception(e)
      nil
    end

    private

    # Le jeton Menshen ne dépend pas de la session de l'agent : on le privilégie tant qu'il est valide
    def token
      if @agent.menshen_access_token.present? && @agent.menshen_access_token_expires_at&.future?
        @agent.menshen_access_token
      else
        @pro_connect_access_token
      end
    end

    def connection
      Faraday.new("#{api_url}/") do |f|
        f.request :json
        f.response :json
        f.options.timeout = 5
        f.options.open_timeout = 2
        f.use :sentry_breadcrumbs, scrub_request_body: true
      end
    end

    def api_url
      ENV.fetch("VISIO_NUMERIQUE_API_URL", DEFAULT_API_URL)
    end
  end
end
