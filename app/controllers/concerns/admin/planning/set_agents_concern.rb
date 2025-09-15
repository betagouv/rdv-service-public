module Admin::Planning::SetAgentsConcern
  extend ActiveSupport::Concern

  included do
    before_action do
      @beta_planning_layout = current_agent.feature_enabled?("new_planning")
    end
  end

  def set_agents
    agents = policy_scope(Agent, policy_scope_class: Agent::AgentPolicy::Scope)
      .where(id: Array(params[:agent_id]).compact_blank)
      .load

    Sentry.add_breadcrumb(Sentry::Breadcrumb.new(message: "agent_id", data: { params: params[:agent_id], scoped: agents.ids }))

    case agents.size
    when 0
      @agent = current_agent
      @agents = [current_agent]
    when 1
      @agent = agents.sole
      @agents = agents
    else
      # Ce cas ne devrait pour le moment pas arriver, il a été mis en place en préparation de l’agenda multi-agents.
      @agents = agents
      Sentry.capture_message("Plusieurs valeurs pour agent_id : cela ne devrait pas arriver")
    end
  end
end
