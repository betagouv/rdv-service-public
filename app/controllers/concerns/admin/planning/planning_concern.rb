module Admin::Planning::PlanningConcern
  extend ActiveSupport::Concern

  included do
    before_action { @planning_layout = true }
    before_action { @current_menu_item = :menu_planning }
  end

  private

  def set_agents
    agent_ids = Array(params[:agent_id]).compact_blank
    agents = policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope)
      .in_order_of(:id, agent_ids) # equivalent to WHERE IN + ORDER BY respecting array values
      .load

    case agents.size
    when 0
      @agent = current_agent
      @agents = [current_agent]
    when 1
      @agent = agents.first
      @agents = [@agent]
    else
      @agents = agents
    end

    if @agents.size > 1
      store_selected_agents(@agents)
    else
      @previously_selected_agents = previously_selected_agents
    end
  end

  def store_selected_agents(agents)
    Redis.with_connection { _1.set(selected_agents_cache_key, agents.map(&:id).join(","), ex: 10.days) }
  end

  def previously_selected_agents
    stored_ids = Redis.with_connection { _1.get(selected_agents_cache_key) }&.split(",").presence
    Agent::AgentPolicy::Scope.apply(current_agent, Agent.all).where(id: stored_ids) if stored_ids
  end

  def selected_agents_cache_key
    "previously_selected_agent_ids:#{current_agent.id}:#{current_organisation.id}"
  end
end
