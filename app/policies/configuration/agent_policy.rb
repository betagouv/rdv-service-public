class Configuration::AgentPolicy
  def initialize(context, agent)
    @current_agent = context.agent
    @current_territory = context.territory
    @agent = agent
    @access_rights = @current_agent.access_rights_for_territory(@current_territory)
  end

  def territorial_admin?
    @current_agent.territorial_admin_in?(@current_territory)
  end

  def territorial_admin_or_allowed_to_manage_agent_part?
    territorial_admin? ||
      @access_rights&.allow_to_manage_access_rights? ||
      @access_rights&.allow_to_manage_teams? ||
      @access_rights&.allow_to_invite_agents?
  end

  alias display? territorial_admin_or_allowed_to_manage_agent_part?
  alias edit? territorial_admin_or_allowed_to_manage_agent_part?
  alias update? territorial_admin_or_allowed_to_manage_agent_part?
  alias territory_admin? territorial_admin_or_allowed_to_manage_agent_part?
  alias update_services? territorial_admin_or_allowed_to_manage_agent_part?

  def create?
    territorial_admin? || @access_rights&.allow_to_invite_agents?
  end

  alias new? create?
end
