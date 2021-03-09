class Agent::ServicePolicy < Agent::AdminPolicy
  class Scope < Scope
    def resolve
      return scope.all if current_agent_role.admin? || current_agent.service.secretariat?

      scope.where(id: current_agent.service_id)
    end
  end

  class AdminScope < Scope
    def resolve
      return scope.all if current_agent_role.admin?

      scope.where(id: current_agent.service_id)
    end
  end
end
