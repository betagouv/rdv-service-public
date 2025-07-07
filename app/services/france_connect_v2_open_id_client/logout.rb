module FranceConnectV2OpenIdClient
  class Logout
    def initialize(france_connect_v2_id_token)
      @france_connect_v2_id_token = france_connect_v2_id_token
      @state = SecureRandom.base58(32)
    end

    attr_reader :state

    def agent_connect_logout_url(post_logout_redirect_url)
      query_params = {
        id_token_hint: @france_connect_v2_id_token,
        state: @state,
        post_logout_redirect_uri: post_logout_redirect_url,
      }

      # voir https://docs.partenaires.franceconnect.gouv.fr/fs/fs-technique/fs-technique-endpoints/#logout-endpoint
      "#{Rails.configuration.x.france_connect_v2_config.end_session_endpoint}?#{query_params.to_query}"
    end
  end
end
