class InclusionConnect
  IC_CLIENT_ID = ENV["INCLUSION_CONNECT_CLIENT_ID"]
  IC_CLIENT_SECRET = ENV["INCLUSION_CONNECT_CLIENT_SECRET"]
  IC_BASE_URL = ENV["INCLUSION_CONNECT_BASE_URL"]

  def self.auth_path(ic_state, inclusion_connect_callback_url, login_hint: nil)
    query = {
      response_type: "code",
      client_id: IC_CLIENT_ID,
      redirect_uri: inclusion_connect_callback_url,
      scope: "openid email profile",
      state: ic_state,
      from: "community",
      login_hint: login_hint,
    }.compact_blank
    "#{IC_BASE_URL}/authorize/?#{query.to_query}"
  end

  def authenticate_and_find_agent(code, inclusion_connect_callback_url)
    token = get_token(code, inclusion_connect_callback_url)
    return if token.blank?

    user_info = get_user_info(token)
    return if user_info.blank?

    agent = find_agent(user_info)
    return unless agent

    update_agent(agent, user_info)
    agent
  end

  private

  def get_token(code, inclusion_connect_callback_url)
    data = {
      client_id: IC_CLIENT_ID,
      client_secret: IC_CLIENT_SECRET,
      code: code,
      grant_type: "authorization_code",
      redirect_uri: inclusion_connect_callback_url,
    }
    uri = URI("#{IC_BASE_URL}/token/")

    res = Typhoeus.post(
      uri,
      body: data,
      headers: { "Content-Type" => "application/x-www-form-urlencoded" }
    )

    return false unless res.success?

    JSON.parse(res.body)["access_token"]
  end

  def get_user_info(token)
    uri = URI("#{IC_BASE_URL}/userinfo/")
    uri.query = URI.encode_www_form({ schema: "openid" })

    res = Typhoeus.get(uri, headers: { "Authorization" => "Bearer #{token}" })

    return false unless res.success?

    JSON.parse(res.body)
  end

  def update_agent(agent, user_info)
    agent.inclusion_connect_open_id_sub ||= user_info["sub"]
    agent.first_name ||= user_info["given_name"]
    agent.last_name ||= user_info["family_name"]

    agent.invitation_accepted_at ||= Time.zone.now
    agent.confirmed_at ||= Time.zone.now

    agent.last_sign_in_at = Time.zone.now
    agent.save!
  end

  def find_agent(user_info)
    found_by_sub = Agent.find_by(inclusion_connect_open_id_sub: user_info["sub"])
    found_by_email = Agent.find_by(email: user_info["email"])

    if found_by_sub && found_by_email && found_by_sub != found_by_email
      Sentry.add_breadcrumb(Sentry::Breadcrumb.new(message: "Found agent with sub", data: { sub: user_info["sub"], agent_id: found_by_sub.id }))
      Sentry.add_breadcrumb(Sentry::Breadcrumb.new(message: "Found agent with email", data: { email: user_info["email"], agent_id: found_by_email.id }))
      Sentry.capture_message("InclusionConnect sub and email mismatch", fingerprint: "ic_agent_sub_email_mismatch")
    end

    found_by_sub || found_by_email
  end
end
