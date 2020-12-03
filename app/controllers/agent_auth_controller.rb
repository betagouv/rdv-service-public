class AgentAuthController < ApplicationController
  rescue_from Pundit::NotAuthorizedError, with: :agent_not_authorized

  layout "application_agent"
  before_action :authenticate_agent!
  before_action :set_paper_trail_whodunnit

  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  helper_method :current_organisation, :policy_scope, :from_modal?

  private

  def user_for_paper_trail
    current_agent.name_for_paper_trail
  end

  def pundit_user
    AgentContext.new(current_agent, current_organisation)
  end
  helper_method :pundit_user

  def authorize(record, *args)
    record.class.module_parent == Agent ? super(record, *args) : super([:agent, record], *args)
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
    current_agent.organisations.find(params[:organisation_id])
  end

  def from_modal?
    params[:modal].present?
  end
end
