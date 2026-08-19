class Agent::AgentTerritorialAccessRightPolicy
  def initialize(agent, agent_territorial_access_right)
    @current_agent = agent
    @agent_territorial_access_right = agent_territorial_access_right
  end

  delegate :allow_to_manage_access_rights?, to: :territory_policy

  def edit?
    allow_to_manage_access_rights? || edit_territory_admin?
  end

  def update?
    if @agent_territorial_access_right.territory_admin_changed?
      return false unless territorial_admin?
    end

    if @agent_territorial_access_right.changes.keys.map(&:to_sym).intersect?(%i[allow_to_manage_teams allow_to_manage_access_rights allow_to_invite_agents])
      return false unless allow_to_manage_access_rights?
    end

    true
  end

  def edit_territory_admin?
    territorial_admin? && agent_in_scope?
  end

  private

  def territory_policy
    Agent::TerritoryPolicy.new(@current_agent, @agent_territorial_access_right.territory)
  end

  def territorial_admin?
    @current_agent.territorial_admin_in?(@agent_territorial_access_right.territory)
  end

  def agent_in_scope?
    Agent::AgentPolicy::Scope.new(@current_agent, Agent).resolve.exists?(id: @agent_territorial_access_right.agent_id)
  end
end
