class Current < ActiveSupport::CurrentAttributes
  attribute :my_agent_ids

  def selected_agents_in_agenda
    raise "woops" unless my_agent_ids.present?

    Agent::AgentPolicy::Scope.new(current_agent, Agent.all).resolve
      .where(id: my_agent_ids)
      .order(last_name: :asc)
      .load
  end
end
