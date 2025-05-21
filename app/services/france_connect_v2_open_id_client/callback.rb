# voir https://github.com/france-connect/Documentation-AgentConnect/blob/main/doc_fs/technique_fca/endpoints.md
module FranceConnectV2OpenIdClient
  class Callback
    class OpenIdFlowError < StandardError; end
    class ApiRequestError < StandardError; end

    def initialize(session_state:, params_state:, callback_url:, nonce:, client_id:, client_secret:)
      @session_state = session_state
      @params_state = params_state
      @callback_url = callback_url
      @nonce = nonce
      @client_id = client_id
      @client_secret = client_secret
    end

    attr_reader :id_token_for_logout, :user_info

    def fetch_user_info_from_code!(code)
      validate_state!

      token = fetch_token(code, @callback_url)

      @user_info = fetch_user_info(token)
    rescue StandardError => e
      Sentry.capture_exception(e)
      nil
    end

    private

    def validate_state!
      if @session_state.blank?
        raise OpenIdFlowError, "blank state in session"
      end

      unless ActiveSupport::SecurityUtils.secure_compare(@session_state, @params_state)
        Sentry.add_breadcrumb(Sentry::Breadcrumb.new(
                                message: "FranceConnect V2 states",
                                data: {
                                  params: @params_state,
                                  session: @session_state,
                                }
                              ))

        raise OpenIdFlowError, "FranceConnect V2 states in session and params do not match"
      end
    end

    def fetch_token(code, agent_connect_callback_url)
      data = {
        client_id: @client_id,
        client_secret: @client_secret,
        code: code,
        grant_type: "authorization_code",
        redirect_uri: agent_connect_callback_url,
      }

      response = Typhoeus.post(
        URI("#{ENV['FRANCECONNECT_V2_BASE_URL']}/token"),
        body: data,
        headers: { "Content-Type" => "application/x-www-form-urlencoded" }
      )

      handle_response_error(response)

      response_hash = JSON.parse(response.body)

      @id_token_for_logout = response_hash["id_token"]
      validate_nonce!(@id_token_for_logout)

      response_hash["access_token"]
    end

    def validate_nonce!(encoded_id_token)
      decoded_id_token = OpenIDConnect::ResponseObject::IdToken.decode(encoded_id_token, france_connect_v2_config.jwks)
      decoded_id_token.verify!(
        issuer: france_connect_v2_config.issuer,
        client_id: @client_id,
        nonce: @nonce
      )
    end

    def fetch_user_info(token)
      uri = URI("#{ENV['FRANCECONNECT_V2_BASE_URL']}/userinfo")
      uri.query = URI.encode_www_form({ schema: "openid" })

      response = Typhoeus.get(uri, headers: { "Authorization" => "Bearer #{token}" })

      handle_response_error(response)

      JWT.decode(response.body, nil, true, algorithms: france_connect_v2_config.jwks.first["alg"], jwks: france_connect_v2_config.jwks).first
    end

    def handle_response_error(response)
      unless response.success?
        raise(ApiRequestError, "code:#{response.response_code}, body:#{response.response_body}")
      end
    end

    def france_connect_v2_config
      Rails.configuration.x.france_connect_v2_config
    end
  end
end
