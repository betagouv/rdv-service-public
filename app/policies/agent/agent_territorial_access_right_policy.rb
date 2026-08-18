class Agent::AgentTerritorialAccessRightPolicy
  def initialize(agent, agent_territorial_access_right)
    @current_agent = agent
    @agent_territorial_access_right = agent_territorial_access_right
  end

  delegate :allow_to_manage_access_rights?, to: :territory_policy

  def edit?
    allow_to_manage_access_rights? || edit_full_rights?
  end
  alias update? edit?

  def edit_full_rights?
    territorial_admin? && visible_agent?
  end

  private

  def territory_policy
    Agent::TerritoryPolicy.new(@current_agent, @agent_territorial_access_right.territory)
  end

  def territorial_admin?
    @current_agent.territorial_admin_in?(@agent_territorial_access_right.territory)
  end

  def visible_agent?
    Agent::AgentPolicy::Scope.new(@current_agent, Agent).resolve.exists?(id: @agent_territorial_access_right.agent_id)
  end
end
