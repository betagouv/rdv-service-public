class Agent::ServicePolicy < Agent::AdminPolicy
  class Scope < Scope
    def resolve
      return scope.all if current_agent_role.admin? || current_agent.secretariat?

      scope.where(id: current_agent.services.map(&:id))
    end
  end

  class AdminScope < Scope
    def resolve
      return scope.all if current_agent_role.admin?

      scope.where(id: current_agent.services.map(&:id))
    end
  end
end
