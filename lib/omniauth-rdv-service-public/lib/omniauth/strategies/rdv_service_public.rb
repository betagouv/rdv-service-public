require "omniauth-oauth2"

module OmniAuth
  module Strategies
    class RdvServicePublic < OmniAuth::Strategies::OAuth2
      option :base_url, "https://demo.rdv.anct.gouv.fr" # L'url de base pour les appels

      def self.sign_out_path
        "/agents/sign_out"
      end

      # On change les options passées en dernier argument par rapport à la classe mère
      def client
        ::OAuth2::Client.new(options.client_id, options.client_secret, client_options)
      end

      info do
        # Envoie une requête sur l'endpoint d'api qui donne les infos de l'agent courant
        access_token.get("/api/v1/agents/me.json").parsed
      end

      private

      def client_options
        {
          site: options.base_url,
          authorize_url: "#{options.base_url}/oauth/authorize",
          token_url: "#{options.base_url}/oauth/token",
        }
      end
    end
  end
end
