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
end
