class AgentConnect
  class AgentNotFoundError < StandardError; end
  class ApiRequestError < StandardError; end

  AGENT_CONNECT_CLIENT_ID = ENV["AGENT_CONNECT_CLIENT_ID"]
  AGENT_CONNECT_CLIENT_SECRET = ENV["AGENT_CONNECT_CLIENT_SECRET"]
  AGENT_CONNECT_BASE_URL = ENV["AGENT_CONNECT_BASE_URL"]

  def initialize(code, agent_connect_callback_url)
    @code = code
    @agent_connect_callback_url = agent_connect_callback_url
  end

  def authenticate_and_find_agent
    @token = fetch_token

    return if user_info.blank?

    return unless matching_agent

    update_agent
    matching_agent
  end

  private

  def fetch_token
    data = {
      client_id: AGENT_CONNECT_CLIENT_ID,
      client_secret: AGENT_CONNECT_CLIENT_SECRET,
      code: @code,
      grant_type: "authorization_code",
      redirect_uri: @agent_connect_callback_url,
    }

    response = Typhoeus.post(
      URI("#{AGENT_CONNECT_BASE_URL}/token/"),
      body: data,
      headers: { "Content-Type" => "application/x-www-form-urlencoded" }
    )

    handle_response_error(response)

    JSON.parse(response.body)["access_token"]
  end

  def user_info
    return @user_info if defined?(@user_info)

    uri = URI("#{AGENT_CONNECT_BASE_URL}/userinfo/")
    uri.query = URI.encode_www_form({ schema: "openid" })

    response = Typhoeus.get(uri, headers: { "Authorization" => "Bearer #{@token}" })

    handle_response_error(response)

    @user_info = JSON.parse(response.body)
  end

  def update_agent
    # We dont want to update one of the agents if we have a mismatch
    return handle_agent_mismatch if agent_mismatch?

    update_basic_info
    update_email(matching_agent) if matching_agent.email != @user_info["email"]
  end

  def update_basic_info
    matching_agent.assign_attributes(
      agent_connect_open_id_sub: matching_agent.agent_connect_open_id_sub || @user_info["sub"],
      first_name: @user_info["given_name"],
      last_name: @user_info["usual_name"],
      invitation_accepted_at: matching_agent.invitation_accepted_at || Time.zone.now,
      # Setting the token to nil to disable old invitations links
      invitation_token: nil,
      confirmed_at: matching_agent.confirmed_at || Time.zone.now,
      last_sign_in_at: Time.zone.now
    )
    matching_agent.save! if matching_agent.changed?
  end

  def update_email(agent)
    agent.email = @user_info["email"]
    agent.skip_reconfirmation!
    agent.save!
  end

  def matching_agent
    return @matching_agent if defined?(@matching_agent)

    handle_agent_mismatch if agent_mismatch?

    @matching_agent = found_by_sub || found_by_email (serveurs webs, jobs cron, etc...)
    raise AgentConnect::AgentNotFoundError, user_info["email"].to_s if @matching_agent.nil?

    @matching_agent
  end

  def handle_agent_mismatch
    Sentry.add_breadcrumb(Sentry::Breadcrumb.new(message: "Found agent with sub", data: { sub: user_info["sub"], agent_id: found_by_sub.id }))
    Sentry.add_breadcrumb(Sentry::Breadcrumb.new(message: "Found agent with email", data: { email: user_info["email"], agent_id: found_by_email.id }))
    Sentry.capture_message("AgentConnect sub and email mismatch", fingerprint: "agent_connect_agent_sub_email_mismatch")
  end

  def found_by_email
    return @found_by_email if defined?(@found_by_email)

    @found_by_email = Agent.active.find_by(email: user_info["email"])
  end

  def found_by_sub
    return log_and_exit("sub") if @user_info["sub"].nil?

    return if @user_info["sub"].nil? && Sentry.capture_message("AgentConnect sub is nil", extra: @user_info, fingerprint: "agent_connect_sub_nil")

    @found_by_sub ||= Agent.active.find_by(agent_connect_open_id_sub: @user_info["sub"])
  end

  def agent_mismatch?
    found_by_sub && found_by_email && found_by_sub != found_by_email
  end

  def handle_response_error(response)
    unless response.success?
      raise(AgentConnect::ApiRequestError, "code:#{response.response_code}, body:#{response.response_body}")
    end
  end
end
