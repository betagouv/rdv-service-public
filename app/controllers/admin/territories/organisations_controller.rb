class Admin::Territories::OrganisationsController < Admin::Territories::BaseController
  def index
    @organisations = policy_scope(current_agent.organisations, policy_scope_class: Agent::OrganisationPolicy::Scope)
      .where(territory: current_territory)
      .ordered_by_name
  end

  private

  def pundit_user
    AgentContext.new(current_agent)
  end
end
