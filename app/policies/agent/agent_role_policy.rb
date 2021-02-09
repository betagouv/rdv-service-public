class Agent::AgentRolePolicy < Agent::AdminPolicy
  def index?
    @record.agent == context.agent
  end

  class Scope < Scope
    def resolve
      scope.where(agent_id: @context.agent.id)
    end
  end
end
