class Agent::ServicePolicy < Agent::AdminPolicy
  class Scope < Scope
    def resolve
      return scope.all if @context.agent_role.admin? || @context.agent.service.secretariat?

      scope.where(id: @context.agent.service_id)
    end
  end

  class AdminScope < Scope
    def resolve
      return scope.all if @context.agent_role.admin?

      scope.where(id: @context.agent.service_id)
    end
  end
end
