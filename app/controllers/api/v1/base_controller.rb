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

    current_agent.organisations.find(params[:organisation_id])
  end

  def policy_scope(clasz)
    super([:agent, clasz])
  end

  def authorize(record, *args)
    super([:agent, record], *args)
  end

  def not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    render status: :forbidden, json: { errors: [t("#{policy_name}.#{exception.query}", scope: "pundit", default: :default)] }
  end

  private

  def serialize_errors(ar_obj)
    ar_obj.errors.map { |field, message| "#{field} #{message}" }
  end
end
