require "omniauth_openid_connect"

module OmniAuth
  module Strategies
    class Franceconnect < OpenIDConnect
      option :client_auth_method, :secret
      option :client_signing_alg, :HS256
      option :state, -> { SecureRandom.hex(16) }
      option :client_options, {
        port: 443,
        scheme: "https",
        authorization_endpoint: "/api/v1/authorize?acr_values=eidas1",
        token_endpoint: "/api/v1/token",
        userinfo_endpoint: "/api/v1/userinfo"
      }
      info do
        {
          sub: user_info.sub,
          given_name: user_info.given_name,
          family_name: user_info.family_name,
          birthdate: user_info.birthdate.presence && Date.parse(user_info.birthdate),
          email: user_info.email,
        }
      end
    end
  end
end

OmniAuth.config.add_camelization("franceconnect", "Franceconnect")
