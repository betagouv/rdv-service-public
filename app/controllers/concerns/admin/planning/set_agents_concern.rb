module Admin::Planning::SetAgentsConcern
  extend ActiveSupport::Concern

  included do
    before_action do
      @beta_planning_layout = current_agent.feature_enabled?("new_planning")
    end
  end

  def set_agents
    scope = policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope)
    agents = Agent.where(id: Array(params[:agent_id]).compact_blank)

    case agents.size
    when 0
      @agent = current_agent
      @agents = [current_agent]
    when 1
      @agent = scope.where(id: agents).first
      @agents = [@agent]
    else
      # Ce cas ne devrait pour le moment pas arriver, il a été mis en place en préparation de l’agenda multi-agents.
      @agents = scope.where(id: agents)
    end
  end
end
