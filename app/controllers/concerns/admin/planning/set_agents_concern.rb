module Admin::Planning::SetAgentsConcern
  extend ActiveSupport::Concern

  def set_agents
    scope = policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope)
    @agents = scope.where(id: params[:agent_id]).presence || [current_agent]
    @agent = @agents.first if @agents.size == 1
  end
end
