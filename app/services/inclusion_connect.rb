# frozen_string_literal: true

module InclusionConnect
  IC_CLIENT_ID = ENV["INCLUSION_CONNECT_CLIENT_ID"]
  IC_CLIENT_SECRET = ENV["INCLUSION_CONNECT_CLIENT_SECRET"]
  IC_BASE_URL = ENV["INCLUSION_CONNECT_BASE_URL"]

  class << self
    def auth_path(ic_state, inclusion_connect_callback_url)
      query = {
        response_type: "code",
        client_id: IC_CLIENT_ID,
        redirect_uri: inclusion_connect_callback_url,
        scope: "openid email",
        state: ic_state,
        nonce: Digest::SHA1.hexdigest("Something to check when it come back ?"),
        from: "community",
      }
      "#{IC_BASE_URL}/auth?#{query.to_query}"
    end

    def agent(code, inclusion_connect_callback_url)
      token = get_token(code, inclusion_connect_callback_url)
      return false if token.blank?

      user_info = get_user_info(token)
      return false if user_info.blank? || (user_info["email_verified"] == false)

      get_and_update_agent(user_info)
    end

    def get_token(code, inclusion_connect_callback_url)
      data = {
        client_id: IC_CLIENT_ID,
        client_secret: IC_CLIENT_SECRET,
        code: code,
        grant_type: "authorization_code",
        redirect_uri: inclusion_connect_callback_url,
      }
      uri = URI("#{IC_BASE_URL}/token")

      res = Typhoeus.post(
        uri,
        body: data,
        headers: { "Content-Type" => "application/x-www-form-urlencoded" }
      )

      return false unless res.success?

      JSON.parse(res.body)["access_token"]
    end

    def get_user_info(token)
      uri = URI("#{IC_BASE_URL}/userinfo")
      uri.query = URI.encode_www_form({ schema: "openid" })

      res = Typhoeus.get(uri, headers: { "Authorization" => "Bearer #{token}" })

      return false unless res.success?

      JSON.parse(res.body)
    end

    def get_and_update_agent(user_info)
      agent = Agent.find_by(email: user_info["email"])
      return if agent.blank?

      agent.update!(
        first_name: user_info["given_name"],
        last_name: user_info["family_name"],
        confirmed_at: Time.zone.now
      )
      agent
    end
  end
end
