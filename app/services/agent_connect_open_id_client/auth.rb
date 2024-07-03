# voir https://github.com/france-connect/Documentation-AgentConnect/blob/main/doc_fs/technique_fca/endpoints.md
module AgentConnectOpenIdClient
  class Auth
    def initialize(login_hint: nil, force_login: false)
      @login_hint = login_hint
      @force_login = force_login
      @state = "agent_connect_state_#{SecureRandom.base58(32)}"
      @nonce = "agent_connect_nonce_#{SecureRandom.base58(32)}"
    end

    attr_reader :state, :nonce

    def redirect_url(callback_url)
      query_params = {
        response_type: "code",
        client_id: ENV["AGENT_CONNECT_CLIENT_ID"],
        redirect_uri: callback_url,
        scope: "openid email given_name usual_name",
        state: state,
        nonce: nonce,
        acr_values: "eidas1",
        login_hint: @login_hint,
        prompt: @force_login ? "login" : nil,
      }.compact_blank

      "#{ENV['AGENT_CONNECT_BASE_URL']}/authorize?#{query_params.to_query}"
    end
  end
end
