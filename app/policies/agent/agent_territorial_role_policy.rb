class Agent::AgentTerritorialRolePolicy
  def initialize(current_agent, agent_territorial_role)
    @current_agent = current_agent
    @agent_territorial_role = agent_territorial_role
  end

  def create_or_destroy?
    territorial_admin? && visible_agent?
  end

  private

  def territorial_admin?
    @current_agent.territorial_admin_in?(@agent_territorial_role.territory)
  end

  def visible_agent?
    context = AgentTerritorialContext.new(@current_agent, @agent_territorial_role.territory)

    Agent::AgentPolicy::Scope.new(context, Agent).resolve.find_by(id: @agent_territorial_role.agent_id)
  end
end
