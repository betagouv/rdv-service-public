class Agent::AgentTerritorialAccessRightPolicy
  def initialize(agent, agent_territorial_access_right)
    @current_agent = agent
    @agent_territorial_access_right = agent_territorial_access_right
  end

  def update?
    @current_agent.territorial_admin_in?(@agent_territorial_access_right.territory)
  end
end
