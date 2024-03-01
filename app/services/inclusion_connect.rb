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

    @user_info = get_user_info(token)
    return if @user_info.blank?

    agent = find_agent
    return unless agent

    update_agent(agent)
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

  def update_agent(agent)
    # We dont want to update one of the agents if we have a mismatch
    return handle_agent_mismatch if agent_mismatch?

    update_basic_info(agent)
    update_email_and_uid(agent) if agent.email != @user_info["email"]
  end

  def update_basic_info(agent)
    agent.assign_attributes({
                              inclusion_connect_open_id_sub: agent.inclusion_connect_open_id_sub || @user_info["sub"],
                              first_name: @user_info["given_name"],
                              last_name: @user_info["family_name"],
                              invitation_accepted_at: agent.invitation_accepted_at || Time.zone.now,
                              confirmed_at: agent.confirmed_at || Time.zone.now,
                              last_sign_in_at: Time.zone.now,
                            })
    agent.save! if agent.changed?
  end

  def update_email_and_uid(agent)
    agent.update_columns(email: @user_info["email"], uid: @user_info["email"]) # rubocop:disable Rails/SkipsModelValidations
  end

  def find_agent
    # Dans le cas ou la migration vers francetravail a été faite mais que son email pole-emploi.fr est encore dans la base
    # Enlever cette condition après la migration
    if @user_info["email"].split("@").last == "francetravail.fr" && found_by_email.nil? && found_by_sub.nil?
      @found_by_email = Agent.find_by(email: @user_info["email"].gsub("francetravail.fr", "pole-emploi.fr"))
    end

    handle_agent_mismatch if agent_mismatch?

    found_by_sub || found_by_email
  end

  def handle_agent_mismatch
    Sentry.add_breadcrumb(Sentry::Breadcrumb.new(message: "Found agent with sub", data: { sub: @user_info["sub"], agent_id: found_by_sub.id }))
    Sentry.add_breadcrumb(Sentry::Breadcrumb.new(message: "Found agent with email", data: { email: @user_info["email"], agent_id: found_by_email.id }))
    Sentry.capture_message("InclusionConnect sub and email mismatch", fingerprint: "ic_agent_sub_email_mismatch")
  end

  def found_by_email
    @found_by_email ||= Agent.find_by(email: @user_info["email"])
  end

  def found_by_sub
    @found_by_sub ||= Agent.find_by(inclusion_connect_open_id_sub: @user_info["sub"])
  end

  def agent_mismatch?
    found_by_sub && found_by_email && found_by_sub != found_by_email
  end
end
