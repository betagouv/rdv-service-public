# frozen_string_literal: true

class Api::V1::BaseController < ActionController::Base
  skip_before_action :verify_authenticity_token
  include Pundit
  include DeviseTokenAuth::Concerns::SetUserByToken
  respond_to :json
  rescue_from Pundit::NotAuthorizedError, with: :not_authorized
  before_action :authenticate_api_v1_agent_with_token_auth!

  def pundit_user
    AgentContext.new(current_agent, current_organisation)
  end

  def current_organisation
    return nil if params[:organisation_id].blank?

    current_agent.organisations.where(id: params[:organisation_id]).first
  end

  def policy_scope(clasz)
    super([:agent, clasz])
  end

  def authorize(record, *args)
    super([:agent, record], *args)
  end

  def not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    render(
      status: :forbidden,
      json: {
        errors: [{ base: :forbidden }],
        error_messages: [t("#{policy_name}.#{exception.query}", scope: "pundit", default: :default)]
      }
    )
  end

  private

  def render_invalid_resource(resource)
    render(
      status: :unprocessable_entity,
      json: {
        success: false,
        errors: resource.errors.details,
        error_messages: resource.errors.map { "#{_1} #{_2}" }
      }
    )
  end
end
