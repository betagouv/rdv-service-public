module AgentConnectOpenIdClient
  class Logout
    def initialize(agent_connect_id_token)
      @agent_connect_id_token = agent_connect_id_token
    end

    def agent_connect_logout_url(post_logout_redirect_url)
      query_params = {
        id_token_hint: @agent_connect_id_token,
        state: SecureRandom.base58(32),
        post_logout_redirect_uri: post_logout_redirect_url,
      }

      # voir # https://github.com/numerique-gouv/agentconnect-documentation/blob/main/doc_fs/implementation_technique.md#42-impl%C3%A9mentation-de-la-route-post_logout_redirect_uri
      "#{Rails.configuration.x.agent_connect_config.end_session_endpoint}?#{query_params.to_query}"
    end
  end
end
