# voir https://github.com/france-connect/Documentation-AgentConnect/blob/main/doc_fs/technique_fca/endpoints.md
class AgentConnectOpenIdClient
  AGENT_CONNECT_CLIENT_ID = ENV["AGENT_CONNECT_CLIENT_ID"]
  AGENT_CONNECT_CLIENT_SECRET = ENV["AGENT_CONNECT_CLIENT_SECRET"]
  AGENT_CONNECT_BASE_URL = ENV["AGENT_CONNECT_BASE_URL"]

  class Auth
    def initialize(login_hint:)
      @login_hint = login_hint
      @state = Digest::SHA1.hexdigest("Agent Connect - #{SecureRandom.base58(16)}")
      @nonce = SecureRandom.base58(32)
    end

    attr_reader :state, :nonce

    def redirect_url(callback_url)
      query_params = {
        response_type: "code",
        client_id: AGENT_CONNECT_CLIENT_ID,
        redirect_uri: callback_url,
        scope: "openid email given_name usual_name",
        state: state,
        nonce: nonce,
        acr_values: "eidas1",
        login_hint: @login_hint,
      }.compact_blank

      "#{AGENT_CONNECT_BASE_URL}/authorize?#{query_params.to_query}"
    end
  end

  class Callback
    class OpenIdFlowError < StandardError; end
    class ApiRequestError < StandardError; end

    include ActiveModel::Validations

    def initialize(session_state:, params_state:, callback_url:)
      @session_state = session_state
      @params_state = params_state
      @callback_url = callback_url
    end

    def fetch_user_info_from_code(code)
      validate_state!
      validate_nonce!

      token = fetch_token(code, @callback_url)

      @user_info = fetch_user_info(token)
    rescue OpenIdFlowError => e
      Sentry.capture_exception(e)
      nil
    end

    def user_email
      @user_info["email"]
    end

    def user_first_name
      @user_info["given_name"].split(" ").first # Agent Connect renvoie aussi le nom de famille après un espace
    end

    def user_last_name
      @user_info["usual_name"]
    end

    private

    def validate_state!
      if @session_state.blank?
        raise OpenIdFlowError, "blank state in session"
      end

      unless ActiveSupport::SecurityUtils.secure_compare(@session_state, @params_state)
        Sentry.add_breadcrumb(Sentry::Breadcrumb.new(
                                message: "Agent Connect states",
                                data: {
                                  params: @params_state,
                                  session: @session_state,
                                }
                              ))

        raise OpenIdFlowError, "State in session and params do not match"
      end
    end

    def validate_nonce!
      # TODO: check nonce here
    end

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

    def handle_response_error(response)
      unless response.success?
        raise(ApiRequestError, "code:#{response.response_code}, body:#{response.response_body}")
      end
    end
  end
end
