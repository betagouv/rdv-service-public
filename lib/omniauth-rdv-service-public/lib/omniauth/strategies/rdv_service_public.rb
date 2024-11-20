require "omniauth-oauth2"

module OmniAuth
  module Strategies
    class RdvServicePublic < OmniAuth::Strategies::OAuth2
      option :base_url, "https://demo.rdv.anct.gouv.fr" # L'url de base pour les appels

      def self.sign_out_path(oauth_client_app_id)
        "/agents/sign_out?oauth_client_app_id=#{oauth_client_app_id}"
      end

      # On change les options passées en dernier argument par rapport à la classe mère
      # pour avoir moins d'options à configurer au niveau de la stratégie
      def client
        ::OAuth2::Client.new(
          options.client_id, options.client_secret,
          {
            site: options.base_url,
            authorize_url: "#{options.base_url}/oauth/authorize",
            token_url: "#{options.base_url}/oauth/token",
          }
        )
      end

      info do
        # Envoie une requête sur l'endpoint d'api qui donne les infos de l'agent courant
        access_token.get("/api/v1/agents/me.json").parsed
      end
    end
  end
end
