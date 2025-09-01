module ProConnectOpenIdClient
  class Logout
    def initialize(pro_connect_id_token)
      @pro_connect_id_token = pro_connect_id_token
    end

    def pro_connect_logout_url(post_logout_redirect_url)
      query_params = {
        id_token_hint: @pro_connect_id_token,
        state: SecureRandom.base58(32),
        post_logout_redirect_uri: post_logout_redirect_url,
      }

      # Voir la section "Implémentation de la route post_logout_redirect_uri" de
      # https://partenaires.proconnect.gouv.fr/docs/fournisseur-service/implementation_technique
      "#{Rails.configuration.x.pro_connect_config.end_session_endpoint}?#{query_params.to_query}"
    end
  end
end
