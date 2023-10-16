# frozen_string_literal: true

class Agent::ServicePolicy < Agent::AdminPolicy
  class Scope < Scope
    def resolve
      if current_agent_role.admin? || current_agent.service.secretariat?
        return scope.in_verticale(current_agent_role.organisation.verticale)
      end

      scope.where(id: current_agent.service_id)
    end
  end

  class AdminScope < Scope
    def resolve
      return scope.secretariat if current_agent.conseiller_numerique?
      return scope.in_verticale(current_agent_role.organisation.verticale) if current_agent_role.admin?

      scope.where(id: current_agent.service_id)
    end
  end
end
