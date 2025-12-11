module Admin::Planning::SetAgentsConcern
  extend ActiveSupport::Concern

  included do
    before_action do
      @beta_planning_layout = current_agent.feature_enabled?(Agent::FeatureFlags::NEW_PLANNING)
    end
  end

  def set_agents_in_session
    selected_agent_ids = Array(params[:selected_agent_ids]).compact_blank.presence
    if selected_agent_ids
      session[:selected_agent_ids_in_agenda] = selected_agent_ids
      self.my_agent_ids = selected_agent_ids
    end
  end

  def set_agents
    scope = policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope)
    selected_agent_ids = Array(params[:selected_agent_ids]).compact_blank.presence
    if selected_agent_ids
      session[:selected_agent_ids_in_agenda] = selected_agent_ids
    end
    agent_ids = Array(params[:agent_id]).compact_blank.presence

    selected_agent_ids = agent_ids || session[:selected_agent_ids_in_agenda].presence || [current_agent.id]
    agents = Agent.where(id: selected_agent_ids)

    case agents.size
    when 0
      @agent = current_agent
      @agents = [current_agent]
    when 1
      @agent = scope.where(id: agents).first
      @agents = [@agent]
    else
      if current_agent.feature_enabled?(Agent::FeatureFlags::NEW_PLANNING)
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
