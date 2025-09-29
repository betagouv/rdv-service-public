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
      if current_agent.feature_enabled?("new_planning")
        @agents = scope.where(id: agents)
      else
        # Si l'agent courant n'a pas activé la feature on ne considère qu'il n'y
        # a qu'un seul agent sélectionné, car le code sera en mode mono-agent.
        @agent = agents.first
        @agents = [@agent]
      end
    end
  end
end
