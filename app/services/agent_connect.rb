class AgentConnect
  class AgentNotFoundError < StandardError; end
  class ApiRequestError < StandardError; end

  AGENT_CONNECT_CLIENT_ID = ENV["AGENT_CONNECT_CLIENT_ID"]
  AGENT_CONNECT_CLIENT_SECRET = ENV["AGENT_CONNECT_CLIENT_SECRET"]
  AGENT_CONNECT_BASE_URL = ENV["AGENT_CONNECT_BASE_URL"]

  def self.auth_path(agent_connect_state, agent_connect_callback_url, login_hint: nil)
    query = {
      response_type: "code",
      client_id: AGENT_CONNECT_CLIENT_ID,
      redirect_uri: agent_connect_callback_url,
      scope: "openid email profile",
      state: agent_connect_state,
      from: "community",
      login_hint: login_hint,
    }.compact_blank
    "#{AGENT_CONNECT_BASE_URL}/authorize/?#{query.to_query}"
  end

  def initialize(code, agent_connect_callback_url)
    @code = code
    @agent_connect_callback_url = agent_connect_callback_url
  end

  def authenticate_and_find_agent
    return if token.blank?

    return if user_info.blank?

    return unless matching_agent

    update_agent
    matching_agent
  end

  private

  def token
    return @token if defined?(@token)

    data = {
      client_id: AGENT_CONNECT_CLIENT_ID,
      client_secret: AGENT_CONNECT_CLIENT_SECRET,
      code: @code,
      grant_type: "authorization_code",
      redirect_uri: @agent_connect_callback_url,
    }
    uri = URI("#{AGENT_CONNECT_BASE_URL}/token/")

    response = Typhoeus.post(
      uri,
      body: data,
      headers: { "Content-Type" => "application/x-www-form-urlencoded" }
    )

    handle_response_error(response)

    @token = JSON.parse(response.body)["access_token"]
  end

  def user_info
    return @user_info if defined?(@user_info)

    uri = URI("#{IC_BASE_URL}/userinfo/")
    uri.query = URI.encode_www_form({ schema: "openid" })

    response = Typhoeus.get(uri, headers: { "Authorization" => "Bearer #{token}" })

    handle_response_error(response)

    @user_info = JSON.parse(response.body)
  end

  def update_agent
    # We dont want to update one of the agents if we have a mismatch
    return handle_agent_mismatch if agent_mismatch?

    update_basic_info
    update_email(matching_agent) if matching_agent.email != user_info["email"]
  end

  def update_basic_info
    matching_agent.assign_attributes(
      {
        agent_connect_open_id_sub: matching_agent.agent_connect_open_id_sub || user_info["sub"],
        first_name: user_info["given_name"],
        last_name: user_info["family_name"],
        invitation_accepted_at: matching_agent.invitation_accepted_at || Time.zone.now,
        # Setting the token to nil to disable old invitations links
        invitation_token: nil,
        confirmed_at: matching_agent.confirmed_at || Time.zone.now,
        last_sign_in_at: Time.zone.now,
      }
    )
    matching_agent.save! if matching_agent.changed?
  end

  def update_email(agent)
    agent.email = user_info["email"]
    agent.skip_reconfirmation!
    agent.save!
  end

  def matching_agent
    return @matching_agent if defined?(@matching_agent)

    handle_agent_mismatch if agent_mismatch?

    @matching_agent = found_by_sub || found_by_email
    raise InclusionConnect::AgentNotFoundError, user_info["email"].to_s if @matching_agent.nil?

    @matching_agent
  end

  def handle_agent_mismatch
    Sentry.add_breadcrumb(Sentry::Breadcrumb.new(message: "Found agent with sub", data: { sub: user_info["sub"], agent_id: found_by_sub.id }))
    Sentry.add_breadcrumb(Sentry::Breadcrumb.new(message: "Found agent with email", data: { email: user_info["email"], agent_id: found_by_email.id }))
    Sentry.capture_message("InclusionConnect sub and email mismatch", fingerprint: "ic_agent_sub_email_mismatch")
  end

  def found_by_email
    return log_and_exit("email") if user_info["email"].nil?

    return @found_by_email if defined?(@found_by_email)

    @found_by_email = Agent.active.find_by(email: user_info["email"])

    unless @found_by_email
      # Les domaines francetravail.fr et pole-emploi.fr sont équivalents
      # Enlever cette condition après la dernière vague de migration le 12 avril
      name, domain = user_info["email"].split("@")
      if domain.in?(["francetravail.fr", "pole-emploi.fr"])
        acceptable_emails = ["#{name}@francetravail.fr", "#{name}@pole-emploi.fr"]
        @found_by_email = Agent.active.find_by(email: acceptable_emails)
      end
    end

    @found_by_email
  end

  def found_by_sub
    return log_and_exit("sub") if user_info["sub"].nil?

    return if user_info["sub"].nil? && Sentry.capture_message("InclusionConnect sub is nil", extra: user_info, fingerprint: "ic_sub_nil")

    @found_by_sub ||= Agent.active.find_by(agent_connect_open_id_sub: user_info["sub"])
  end

  def log_and_exit(field)
    # should not happen
    Sentry.capture_message("InclusionConnect #{field} is nil", extra: user_info, fingerprint: "ic_#{field}_nil")
    nil
  end

  def agent_mismatch?
    found_by_sub && found_by_email && found_by_sub != found_by_email
  end

  def handle_response_error(response)
    unless response.success?
      raise(InclusionConnect::ApiRequestError, "code:#{response.response_code}, body:#{response.response_body}")
    end
  end
end
