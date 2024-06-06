module AgentConnectOpenIdClient
  class Auth
    def initialize(login_hint: nil, force_login: false)
      @login_hint = login_hint
      @force_login = force_login
      @state = "Agent Connect State - #{SecureRandom.base58(32)}"
      @nonce = "Agent Connect Nonce - #{SecureRandom.base58(32)}"
    end

    attr_reader :state, :nonce

    def redirect_url(callback_url)
      query_params = {
        response_type: "code",
        client_id: AGENT_CONNECT_CLIENT_ID,
        redirect_uri: callback_url,
        scope: "openid email given_name usual_name",
        state: state,
        nonce: nonce,
        acr_values: "eidas1",
        login_hint: @login_hint,
        prompt: @force_login ? "login" : nil,
      }.compact_blank

      "#{AGENT_CONNECT_BASE_URL}/authorize?#{query_params.to_query}"
    end
  end
end
