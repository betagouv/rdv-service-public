module Admin::Planning::SetAgentsConcern
  extend ActiveSupport::Concern

  included do
    before_action do
      @beta_planning_layout = current_agent.feature_enabled?(Agent::FeatureFlags::NEW_PLANNING)
    end
  end

  private

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
      if current_agent.feature_enabled?(Agent::FeatureFlags::NEW_PLANNING)
        @agents = scope.where(id: agents).load
      else
        # Si l'agent courant n'a pas activé la feature on ne considère qu'il n'y
        # a qu'un seul agent sélectionné, car le code sera en mode mono-agent.
        @agent = agents.first
        @agents = [@agent]
      end
    end

    store_selected_agents(@agents) unless @agents == [current_agent]
    @previously_selected_agents = previously_selected_agents
  end

  def store_selected_agents(agents)
    current_agent.append_agent_selection!(agents.map(&:id))
  end

  def previously_selected_agents
    current_agent.latest_agent_selections.map do |agent_ids|
      Agent::AgentPolicy::Scope.apply(current_agent, Agent.all).where(id: agent_ids)
    end
  end

  def selected_agents_cache_key
    "previously_selected_agent_ids:#{current_agent.id}:#{current_organisation.id}"
  end
end
