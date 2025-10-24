module Admin::Planning::SetAgentsConcern
  extend ActiveSupport::Concern

  included do
    before_action do
      @beta_planning_layout = current_agent.feature_enabled?(Agent::FeatureFlags::NEW_PLANNING)
    end
  end

  def set_agents
    agents = Agent::AgentPolicy::Scope.new(current_agent, Agent).resolve
      .where(id: Array(params[:agent_id]).compact_blank)
      .load

    case agents.size
    when 0
      @agent = current_agent
      @agents = [current_agent]
    when 1
      @agent = agents.sole
      @agents = [agents.sole]
    else
      if current_agent.feature_enabled?(Agent::FeatureFlags::NEW_PLANNING)
        @agents = agents
      else
        # Si l'agent courant n'a pas activé la feature, on ne considère qu'il n'y
        # a qu'un seul agent sélectionné, car le code sera en mode mono-agent.
        @agent = agents.first
        @agents = [agents.first]
      end
    end
  end
end
