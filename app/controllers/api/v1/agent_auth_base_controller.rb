class Api::V1::AgentAuthBaseController < Api::V1::BaseController
  include Pundit::Authorization
  include DeviseTokenAuth::Concerns::SetUserByToken
  # le Json d'erreur de DeviseTokenAuth n'est pas compliant avec le module ApiException::Handler
  # Il faudrait trouver une solution pour formatter les erreurs de DeviseTokenAuth

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

  def authorize(record, *args)
    super([:agent, record], *args)
  end

  # Rescuable exceptions

  rescue_from Pundit::NotAuthorizedError, with: :not_authorized

  def not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    # Je ne peux pas faire ca ici, investiguer pourquoi ?
    # raise ApiException::Forbidden, t("#{policy_name}.#{exception.query}", scope: "pundit", default: :default)
    render(
      status: :forbidden,
      json: {
        success: false,
        message: "Unauthorized",
        detail: t("#{policy_name}.#{exception.query}", scope: "pundit", default: :default),
      }
    )
  end

  private

  # L'usage recommandé est de passer explicitement une policy_scope_class pour savoir quelle policy est utilisé
  # A terme, on voudra forcer l'argument policy_scope_class
  def policy_scope(scope, policy_scope_class: nil)
    if policy_scope_class
      super(scope, policy_scope_class: policy_scope_class)
    else
      super([:agent, scope])
    end
  end

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
