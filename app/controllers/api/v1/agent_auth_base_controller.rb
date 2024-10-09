class Api::V1::AgentAuthBaseController < Api::V1::BaseController
  include ExplicitPunditConcern
  include DeviseTokenAuth::Concerns::SetUserByToken

  skip_before_action :verify_authenticity_token
  before_action :authenticate_agent, :log_api_call_in_database

  def pundit_user
    AgentOrganisationContext.new(current_agent, current_organisation)
  end

  def current_organisation
    @current_organisation ||=
      if params[:organisation_id].blank?
        nil
      else
        current_agent.organisations.find_by(id: params[:organisation_id])
      end
  end

  # Rescuable exceptions

  rescue_from Pundit::NotAuthorizedError, with: :not_authorized
  rescue_from ActionController::ParameterMissing, with: :parameter_missing
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid

  def not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    render(
      status: :forbidden,
      json: {
        errors: [{ base: :forbidden }],
        error_messages: [t("#{policy_name}.#{exception.query}", scope: "pundit", default: :default)],
      }
    )
  end

  def parameter_missing(exception)
    render(
      status: :unprocessable_entity,
      json: { success: false, errors: [exception.to_s] }
    )
  end

  def record_not_found(exception)
    render(
      status: :not_found,
      json: { success: false, errors: [exception.to_s] }
    )
  end

  def record_invalid(exception)
    render(
      status: :unprocessable_entity,
      json: {
        success: false,
        errors: exception.record.errors.details,
        error_messages: exception.record.errors.map { "#{_1.attribute} #{_1.message}" },
      }
    )
  end

  private

  def authenticate_agent
    if request.headers.include?("X-Agent-Auth-Signature")
      # Bypass DeviseTokenAuth
      authenticate_agent_with_shared_secret
    else
      # Use DeviseTokenAuth
      authenticate_api_v1_agent_with_token_auth!
    end
  end

  def authenticate_agent_with_shared_secret
    if shared_secret_is_valid?
      @current_agent = Agent.find_by(email: request.headers["uid"])
    else
      Sentry.capture_message("API authentication agent was called with an invalid signature !", fingerprint: ["api_agent_invalid_sig"])
      render(
        status: :unauthorized,
        json: {
          errors: [I18n.t("devise.failure.unauthenticated")],
        }
      )
    end
  end

  def shared_secret_is_valid?
    return false if request.headers["X-Agent-Auth-Signature"].nil?

    agent = Agent.find_by(email: request.headers["uid"])
    # Structure of the payload need to be exact for digest comparison
    payload = {
      id: agent.id,
      first_name: agent.first_name,
      last_name: agent.last_name,
      email: agent.email,
    }

    ActiveSupport::SecurityUtils.secure_compare(
      OpenSSL::HMAC.hexdigest("SHA256", ENV.fetch("SHARED_SECRET_FOR_AGENTS_AUTH"), payload.to_json),
      request.headers["X-Agent-Auth-Signature"]
    )
  end

  def log_api_call_in_database
    raw_http = {
      method: request.method,
      path: request.fullpath,
      host: request.host,
      # We only keep headers that are uppercase (convention for HTTP headers)
      headers: request.headers.select { |key, _| key == key.upcase }.to_h.transform_values { |value| value.is_a?(String) ? value : value.inspect },
    }

    ApiCall.create!(
      raw_http: raw_http,
      controller_name: controller_name,
      action_name: action_name,
      agent_id: current_agent.id
    )
  rescue StandardError => e
    Sentry.capture_exception(e, extra: {
                               raw_http: raw_http,
                               controller_name: controller_name,
                               action_name: action_name,
                               agent_id: current_agent&.id,
                             })
  end
end
