class Agent::TerritoryPolicy
  def initialize(current_agent, territory)
    @current_agent = current_agent
    @territory = territory
  end

  def territorial_admin?
    @current_agent.territorial_roles.exists?(territory_id: @territory.id)
  end

  alias update? territorial_admin?
  alias edit? territorial_admin?

  def show?
    territorial_admin? ||
      access_rights&.allow_to_manage_access_rights? ||
      access_rights&.allow_to_invite_agents? ||
      access_rights&.allow_to_manage_teams?
  end

  class Scope
    def initialize(current_agent, scope)
      @current_agent = current_agent
      @scope = scope
    end

    def resolve
      @scope.joins(:roles).where(roles: { agent: @current_agent })
    end
  end

  private

  def access_rights
    @access_rights ||= @current_agent.agent_territorial_access_rights.find_by(territory: @territory)
  end
end
