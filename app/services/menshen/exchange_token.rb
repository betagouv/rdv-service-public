# Échange un access token ProConnect contre un jeton Menshen (La Suite numérique),
# utilisable plus tard sans dépendre de la session de l'agent qui s'est connecté.
# cf https://github.com/suitenumerique/menshen/blob/main/docs/la-suite.md (RFC 8693 token exchange)
module Menshen
  class ExchangeToken
    class ApiError < StandardError; end
    class ClientError < ApiError; end

    REQUIRED_ENV_VARS = %w[MENSHEN_BASE_URL MENSHEN_AUDIENCE].freeze

    # Menshen n'est pas configuré partout (review apps, démo…), ni forcément pour tous les domaines
    def self.configured?(domain)
      REQUIRED_ENV_VARS.all? { ENV[_1].present? } && domain.menshen_client_id.present? && domain.menshen_client_secret.present?
    end

    def initialize(subject_token:, domain:)
      @subject_token = subject_token
      @domain = domain
    end

    def call
      response = connection.post("auth/token/exchange/") do |req|
        req.body = {
          grant_type: "urn:ietf:params:oauth:grant-type:token-exchange",
          subject_token: @subject_token,
          subject_token_type: "urn:ietf:params:oauth:token-type:access_token",
          audience: ENV.fetch("MENSHEN_AUDIENCE"),
          scope: "action:create-meet-room",
        }
      end

      raise ClientError, "HTTP #{response.status}: #{response.body}" if response.status.in?(400..499)
      raise ApiError, "HTTP #{response.status}: #{response.body}" unless response.success?

      response.body
    end

    private

    def connection
      Faraday.new(ENV.fetch("MENSHEN_BASE_URL")) do |f|
        f.request :url_encoded
        f.request :authorization, :basic, @domain.menshen_client_id, @domain.menshen_client_secret
        f.response :json
        f.options.timeout = 5
        f.options.open_timeout = 2
        # Le header Authorization contient le client secret, et la réponse le jeton Menshen
        f.use :sentry_breadcrumbs, scrub_request_body: true, scrub_authorization_header: true, scrub_response_body: true
      end
    end
  end
end
