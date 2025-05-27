class Admin::AgendaMultiAgentsController < AgentAuthController
  def index
    @selectable_agents = policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope).active
    @selected_agents = @selectable_agents.where(id: params[:agent_ids])
  end
end
