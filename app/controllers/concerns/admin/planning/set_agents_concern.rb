module Admin::Planning::SetAgentsConcern
  extend ActiveSupport::Concern

  def set_agents
    scope = policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope)
    agent_ids = Array(params[:agent_id]).compact_blank

    case agent_ids.size
    when 0
      @agent = current_agent
      @agents = [current_agent]
    when 1
      @agent = scope.find(agent_ids.first)
      @agents = [@agent]
    else
      @agents = scope.where(id: agent_ids)
    end
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "L'agent sélectionné est introuvable"
    redirect_to root_path
  end
end
