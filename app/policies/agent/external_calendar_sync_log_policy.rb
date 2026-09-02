class Agent::ExternalCalendarSyncLogPolicy
  class Scope
    def initialize(current_agent, scope)
      @current_agent = current_agent
      @scope = scope
    end

    def resolve
      @scope.where(agent_id: @current_agent.id)
    end
  end
end
