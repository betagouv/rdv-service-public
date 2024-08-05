class Agent::AgentTerritorialRolePolicy
  def initialize(current_agent, agent_territorial_role)
    @current_agent = current_agent
    @agent_territorial_role = agent_territorial_role
  end

  def create_or_destroy?
    @current_agent.territorial_admin_in?(@agent_territorial_role.territory)
  end
end
