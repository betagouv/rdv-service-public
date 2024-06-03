# voir https://github.com/france-connect/Documentation-AgentConnect/blob/main/doc_fs/technique_fca/endpoints.md
class AgentConnect
  class AgentNotFoundError < StandardError; end
  class ApiRequestError < StandardError; end

  AGENT_CONNECT_CLIENT_ID = ENV["AGENT_CONNECT_CLIENT_ID"]
  AGENT_CONNECT_CLIENT_SECRET = ENV["AGENT_CONNECT_CLIENT_SECRET"]
  AGENT_CONNECT_BASE_URL = ENV["AGENT_CONNECT_BASE_URL"]

  def authenticate_and_find_agent(code, agent_connect_callback_url)
    token = fetch_token(code, agent_connect_callback_url)

    @user_info = fetch_user_info(token)

    return unless matching_agent

    update_agent
    matching_agent
  end

  private

  def fetch_token(code, agent_connect_callback_url)
    data = {
      client_id: AGENT_CONNECT_CLIENT_ID,
      client_secret: AGENT_CONNECT_CLIENT_SECRET,
      code: code,
      grant_type: "authorization_code",
      redirect_uri: agent_connect_callback_url,
    }

    response = Typhoeus.post(
      URI("#{AGENT_CONNECT_BASE_URL}/token"),
      body: data,
      headers: { "Content-Type" => "application/x-www-form-urlencoded" }
    )

    handle_response_error(response)

    JSON.parse(response.body)["access_token"]
  end

  def fetch_user_info(token)
    uri = URI("#{AGENT_CONNECT_BASE_URL}/userinfo")
    uri.query = URI.encode_www_form({ schema: "openid" })

    response = Typhoeus.get(uri, headers: { "Authorization" => "Bearer #{token}" })

    handle_response_error(response)

    JWT.decode(response.body, nil, true, algorithms: AGENT_CONNECT_CONFIG.jwks.first["alg"], jwks: AGENT_CONNECT_CONFIG.jwks).first
  end

  def update_agent
    matching_agent.update!(
      connected_with_agent_connect: true,
      first_name: @user_info["given_name"].split(" ").first,
      last_name: @user_info["usual_name"],
      invitation_accepted_at: matching_agent.invitation_accepted_at || Time.zone.now,
      confirmed_at: matching_agent.confirmed_at || Time.zone.now,
      invitation_token: nil, # Setting the token to nil to disable old invitations links
      last_sign_in_at: Time.zone.now
    )
  end

  def matching_agent
    @matching_agent ||= find_matching_agent
  end

  def find_matching_agent
    # Agent Connect recommande de faire la réconciliation sur l'email et non pas sur le sub
    # voir https://github.com/france-connect/Documentation-AgentConnect/blob/main/doc_fs/projet_fca/projet_fca_donnees.md
    agent = Agent.active.find_by(email: @user_info["email"])

    raise AgentConnect::AgentNotFoundError, @user_info["email"].to_s if agent.nil?

    agent
  end

  def handle_response_error(response)
    unless response.success?
      raise(AgentConnect::ApiRequestError, "code:#{response.response_code}, body:#{response.response_body}")
    end
  end
end
