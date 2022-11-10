# frozen_string_literal: true

class Api::V1::AgentAuthBaseController < Api::V1::BaseController
  include Pundit::Authorization
  include DeviseTokenAuth::Concerns::SetUserByToken

  skip_before_action :verify_authenticity_token
  before_action :authenticate_api_v1_agent_with_token_auth!

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

  def policy_scope(clasz)
    super([:agent, clasz])
  end

  def authorize(record, *args)
    super([:agent, record], *args)
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

  def record_not_found(_)
    head :not_found
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
end
