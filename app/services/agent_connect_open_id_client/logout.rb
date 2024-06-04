module AgentConnectOpenIdClient
  class Logout
    def initialize(agent_connect_id_token)
      @agent_connect_id_token = agent_connect_id_token
    end

    def agent_connect_logout_url(post_logout_redirect_url)
      query_params = {
        id_token_hint: @agent_connect_id_token,
        state: SecureRandom.base58(32),
        # TODO: ajouter un test pour mettre un avertissement si after_sign_out_path_for(:agent) change
        post_logout_redirect_uri: post_logout_redirect_url,
      }

      "#{AGENT_CONNECT_CONFIG.end_session_endpoint}?#{query_params.to_query}"
    end
  end
end
