class AgendasController < DashboardAuthController
  before_action :redirect_if_agent_incomplete, only: :index

  def index
    skip_policy_scope
    @organisation = current_agent.organisation
  end

  private

  def redirect_if_agent_incomplete
    return unless agent_signed_in?

    redirect_to(new_agents_full_subscription_path) && return unless current_agent.complete?
    redirect_to(new_organisation_path) && return if current_agent.organisation.nil?
  end
end
