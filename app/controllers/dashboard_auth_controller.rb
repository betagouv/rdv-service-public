class DashboardAuthController < ApplicationController
  rescue_from Pundit::NotAuthorizedError, with: :agent_not_authorized

  before_action :authenticate_agent!

  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  helper_method :current_organisation

  private

  def pundit_user
    AgentContext.new(current_agent, current_organisation)
  end

  def authorize(record)
    record.class.module_parent == Agent ? super(record) : super([:agent, record])
  end

  def policy_scope(clasz)
    clasz.module_parent == Agent ? super(record) : super([:agent, clasz])
  end

  def agent_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    flash[:error] = t "#{policy_name}.#{exception.query}", scope: "pundit", default: :default
    redirect_to(request.referrer || authenticated_agent_root_path)
  end

  def set_organisation
    @organisation = current_organisation
  end

  def current_organisation
    id = params[:controller] == "organisations" ? params[:id] : params[:organisation_id]
    id ? current_agent.organisations.find(id) : current_agent.organisations.first
  rescue ActiveRecord::RecordNotFound
    raise Pundit::NotAuthorizedError
  end
end
