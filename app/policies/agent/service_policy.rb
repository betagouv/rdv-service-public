class Agent::ServicePolicy < Agent::AdminPolicy
  class Scope < Scope
    def resolve
      if current_agent_role.admin? || current_agent.secretaire?
        return scope.in_verticale(current_agent_role.organisation.verticale)
      end

      scope.where(id: current_agent.services.select(:id))
    end
  end

  class AdminScope < Scope
    def resolve
      return scope.in_verticale(current_agent_role.organisation.verticale) if current_agent_role.admin?

      scope.where(id: current_agent.services.select(:id))
    end
  end
end
