# voir https://partenaires.proconnect.gouv.fr/docs/fournisseur-service/implementation_technique
module ProConnectOpenIdClient
  class Auth
    BASE_SCOPES = "openid email given_name usual_name siret idp_id".freeze
    VISIO_SCOPES = "lasuite_visio lasuite_visio:rooms:create".freeze
    ACR_FOR_2FA = %w[eidas0-mfa eidas1-mfa eidas2 eidas3].freeze

    def initialize(client_id:, client_secret:, login_hint: nil, prompt: nil)
      @login_hint = login_hint
      @state = "pro_connect_state_#{SecureRandom.base58(32)}"
      @nonce = "pro_connect_nonce_#{SecureRandom.base58(32)}"
      @client_id = client_id
      @client_secret = client_secret
      @prompt = prompt
    end

    attr_reader :state, :nonce

    def redirect_url(callback_url, force_2fa: false)
      query_params = {
        response_type: "code",
        client_id: @client_id,
        redirect_uri: callback_url,
        scope: scopes,
        state: state,
        nonce: nonce,
        login_hint: @login_hint,
        prompt: @prompt,
        claims: claims(force_2fa:).to_json,
      }.compact_blank

      "#{ENV['PRO_CONNECT_BASE_URL']}/authorize?#{query_params.to_query}"
    end

    private

    def scopes
      return BASE_SCOPES if ENV["VISIO_NUMERIQUE_DISABLED"]

      "#{BASE_SCOPES} #{VISIO_SCOPES}"
    end

    def claims(force_2fa:)
      {
        id_token: {
          acr: {
            essential: force_2fa,
            values: ACR_FOR_2FA,
          },
        },
      }
    end
  end
end
