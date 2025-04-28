class Agent::TerritoryPolicy
  def initialize(current_agent, territory)
    @current_agent = current_agent
    @territory = territory
    @access_rights = @current_agent.agent_territorial_access_rights.find_by(territory_id: territory.id)
  end

  def territorial_admin?
    @current_agent.territorial_roles.exists?(territory_id: @territory.id)
  end

  alias update? territorial_admin?
  alias edit? territorial_admin?

  def new?
    return false if @current_agent.agent_territorial_access_rights.any?

    OauthApplication.agent_is_verified_by_an_application?(@current_agent)
  end
  alias create? new?

  def show?
    territorial_admin? ||
      allow_to_manage_teams? ||
      allow_to_manage_access_rights? ||
      allow_to_invite_agents?
  end

  def allow_to_manage_access_rights?
    @access_rights&.allow_to_manage_access_rights?
  end

  def allow_to_invite_agents?
    @access_rights&.allow_to_invite_agents?
  end

  def allow_to_manage_teams?
    @access_rights&.allow_to_manage_teams?
  end

  class Scope
    def initialize(current_agent, scope)
      @current_agent = current_agent
      @scope = scope
    end

    def resolve
      territories_with_roles = @scope.joins(:roles)
        .where(agent_territorial_roles: { agent: @current_agent })

      territories_with_rights = @scope.joins(:agent_territorial_access_rights)
        .where(agent_territorial_access_rights: { agent: @current_agent })
        .merge(AgentTerritorialAccessRight.with_some_rights_allowed)

      @scope.where_id_in_subqueries([territories_with_roles, territories_with_rights])
    end
  end
end
