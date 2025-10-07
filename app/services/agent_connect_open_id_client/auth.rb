# voir https://partenaires.proconnect.gouv.fr/docs/fournisseur-service/implementation_technique
module AgentConnectOpenIdClient
  class Auth
    SCOPES = "openid email given_name usual_name siret".freeze
    ACR_FOR_2FA = %w[eidas2 eidas3 https://proconnect.gouv.fr/assurance/consistency-checked-2fa https://proconnect.gouv.fr/assurance/self-asserted-2fa].freeze

    def initialize(client_id:, client_secret:, login_hint: nil, force_login: false)
      @login_hint = login_hint
      @force_login = force_login
      @state = "agent_connect_state_#{SecureRandom.base58(32)}"
      @nonce = "agent_connect_nonce_#{SecureRandom.base58(32)}"
      @client_id = client_id
      @client_secret = client_secret
    end

    attr_reader :state, :nonce

    def redirect_url(callback_url, force_2fa: false)
      query_params = {
        response_type: "code",
        client_id: @client_id,
        redirect_uri: callback_url,
        scope: SCOPES,
        state: state,
        nonce: nonce,
        login_hint: @login_hint,
        prompt: @force_login ? "login" : nil,
        claims: claims(force_2fa:).to_json,
      }.compact_blank

      "#{ENV['AGENT_CONNECT_BASE_URL']}/authorize?#{query_params.to_query}"
    end

    private

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
