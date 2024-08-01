class Agent::AgentRolePolicy
  def initialize(current_agent, agent_role)
    @current_agent = current_agent
    @agent_role = agent_role
    @access_rights = @current_agent.access_rights_for_territory(agent_role.organisation.territory)
  end

  def territorial_admin_or_can_invite_agents?
    @current_agent.territorial_admin_in?(@agent_role.organisation.territory) ||
      @access_rights&.allow_to_invite_agents?
  end

  alias update? territorial_admin_or_can_invite_agents?
  alias edit? territorial_admin_or_can_invite_agents?
  alias create? territorial_admin_or_can_invite_agents?
  alias destroy? territorial_admin_or_can_invite_agents?

  class Scope < ApplicationPolicy::Scope
    include CurrentAgentInPolicyConcern

    def resolve
      my_roles = scope.merge(current_agent.roles)
      roles_of_orgs_i_admin = scope.where(organisation: current_agent.admin_orgs)

      my_roles.or roles_of_orgs_i_admin
    end
  end
end
