# frozen_string_literal: true

class Agent::ServicePolicy < Agent::AdminPolicy
  class Scope < Scope
    def resolve
      available_services = scope.where(
        verticale: [current_agent_role.organisation.verticale, nil]
      )

      return available_services if current_agent_role.admin? || current_agent.service.secretariat?

      scope.where(id: current_agent.service_id)
    end
  end

  class AdminScope < Scope
    def resolve
      available_services = scope.where(
        verticale: [current_agent_role.organisation.verticale, nil]
      )

      return scope.secretariat if current_agent.conseiller_numerique?
      return available_services if current_agent_role.admin?

      scope.where(id: current_agent.service_id)
    end
  end
end
