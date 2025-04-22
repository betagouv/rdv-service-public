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
        userinfo_endpoint: "/api/v1/userinfo",
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

      def request_phase
        res = super # call super before so that session state is set
        Redis.with_connection do |redis|
          key = self.class.redis_key_for_state(session["omniauth.state"])
          redis.hsetnx key, "created_at", Time.zone.now.to_s
          redis.hsetnx key, "user_agent", request.user_agent
          redis.expireat key, 2.days.from_now
        end
        res
      end

      def callback_phase
        # cf https://github.com/betagouv/rdv-service-public/issues/4637
        request = Rack::Request.new(env)
        state_from_params = request.params["state"]
        state_from_session = env["rack.session"]["omniauth.state"]
        if state_from_session != state_from_params
          redis_key = self.class.redis_key_for_state(state_from_params)
          redis_data = Redis.with_connection { |r| r.hgetall redis_key }
          Sentry.set_context(
            :omni_callback, # NOTE: ne pas utiliser 'auth' dans le nom du contexte sinon Sentry le scrubbe
            {
              state_from_session:,
              state_from_params:,
              current_user_agent: request.user_agent,
              stored_state_created_at: redis_data&.fetch("created_at", nil),
              stored_state_user_agent: redis_data&.fetch("user_agent", nil),
            }
          )
        end
        super
      end

      def self.redis_key_for_state(state)
        state.present? && "omniauth:franceconnect:state:#{state}"
      end
    end
  end
end

OmniAuth.config.add_camelization("franceconnect", "Franceconnect")
