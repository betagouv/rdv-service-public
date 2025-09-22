# voir https://partenaires.proconnect.gouv.fr/docs/fournisseur-service/implementation_technique
module AgentConnectOpenIdClient
  class Auth
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
      scopes = "openid email given_name usual_name siret"

      # Voir https://partenaires.proconnect.gouv.fr/docs/fournisseur-service/double_authentification
      claims = if force_2fa
                 {
                   id_token: {
                     acr: {
                       essential: true,
                       values: %w[eidas2 eidas3 https://proconnect.gouv.fr/assurance/consistency-checked-2fa https://proconnect.gouv.fr/assurance/self-asserted-2fa],
                     },
                   },
                 }
               else
                 {
                   id_token: {
                     acr: {
                       essential: true,
                       values: [
                         "eidas1",
                       ],
                     },
                   },
                 }
               end

      query_params = {
        response_type: "code",
        client_id: @client_id,
        redirect_uri: callback_url,
        scope: scopes,
        state: state,
        nonce: nonce,
        login_hint: @login_hint,
        prompt: @force_login ? "login" : nil,
        claims: claims.to_json,
      }.compact_blank

      "#{ENV['AGENT_CONNECT_BASE_URL']}/authorize?#{query_params.to_query}"
    end
  end
end
