# voir # https://github.com/numerique-gouv/agentconnect-documentation/blob/main/doc_fs/implementation_technique.md
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

    def redirect_url(callback_url)
      query_params = {
        response_type: "code",
        client_id: @client_id,
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
