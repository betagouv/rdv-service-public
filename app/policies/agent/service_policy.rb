# frozen_string_literal: true

class Agent::ServicePolicy < Agent::AdminPolicy
  class Scope < Scope
    def resolve
      territory = current_agent_role.organisation.territory
      return scope.all_for_territory(territory) if current_agent_role.admin? || current_agent.service.secretariat?

      scope.where(id: current_agent.service_id)
    end
  end

  class AdminScope < Scope
    def resolve
      territory = current_agent_role.organisation.territory
      return scope.secretariat if current_agent.conseiller_numerique?
      return scope.all_for_territory(territory) if current_agent_role.admin?

      scope.where(id: current_agent.service_id)
    end
  end
end
