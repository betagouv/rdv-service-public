class Configuration::AgentRolePolicy
  def initialize(context, agent_role)
    @current_agent = context.agent
    @agent_role = agent_role
    @access_rights = @current_agent.access_rights_for_territory(agent_role.organisation.territory)
  end

  def territorial_admin?
    @current_agent.territorial_admin_in?(@agent_role.organisation.territory) ||
      @access_rights&.allow_to_invite_agents?
  end

  alias update? territorial_admin?
  alias edit? territorial_admin?
  alias create? territorial_admin?
  alias destroy? territorial_admin?
end
