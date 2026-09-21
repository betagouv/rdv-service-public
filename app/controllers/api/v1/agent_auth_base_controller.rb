class Api::V1::AgentAuthBaseController < Api::V1::BaseController
  include ExplicitPunditConcern
  include DeviseTokenAuth::Concerns::SetUserByToken

  skip_before_action :verify_authenticity_token
  before_action :authenticate_agent
  before_action :log_api_call_in_database
  before_action :set_paper_trail_whodunnit
  before_action :set_sentry_context

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

  rescue_from StandardError, with: :unexpected_error
  rescue_from Pundit::NotAuthorizedError, with: :not_authorized
  rescue_from ActionController::ParameterMissing, with: :parameter_missing
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid

  def unexpected_error(exception)
    Sentry.capture_exception(exception)
    render(
      status: :internal_server_error,
      json: { errors: ["Unexpected internal error"] }
    )
  end

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
      json: { errors: [exception.to_s] }
    )
  end

  def record_not_found(exception)
    render(
      status: :not_found,
      json: { errors: [exception.to_s] }
    )
  end

  def record_invalid(exception)
    render(
      status: :unprocessable_entity,
      json: {
        errors: exception.record.errors.details,
        error_messages: exception.record.errors.map { "#{_1.attribute} #{_1.message}" },
      }
    )
  end

  private

  def authenticate_agent
    if request.headers["HTTP_ACCESS_TOKEN"] && request.headers["HTTP_UID"] && ENV["AUTHORIZE_DEPRECATED_API_AUTH"].present?
      # Ce mode d'authentification est déprécié, et n'est autorisé que sur l'instance historique
      authenticate_api_v1_agent_with_token_auth!
      @authentication_type = "DeviseTokenAuth"
    else
      doorkeeper_authorize!
      if doorkeeper_token
        @authentication_type = "OAuth"
        @current_agent = Agent.find(doorkeeper_token.resource_owner_id)
      end
    end
  end

  def user_for_paper_trail
    "#{current_agent.name_for_paper_trail} (via API)"
  end

  def set_sentry_context
    Sentry.set_user(id: current_agent.id, email: current_agent.email)
  end

  def log_api_call_in_database
    raw_http = {
      method: request.method,
      path: request.fullpath,
      host: request.host,
    }

    param_names = request.query_parameters.keys

    if request.raw_post.present?
      parsed_params = begin
        JSON.parse(request.raw_post)
      rescue StandardError
        {}
      end

      param_names += parsed_params.keys
    end

    ApiCall.create!(
      raw_http: raw_http,
      controller_name: controller_name,
      action_name: action_name,
      agent_id: current_agent.id,
      authentication_type: @authentication_type,
      param_names: param_names
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
