# frozen_string_literal: true

class Agent::PlageOuverturePolicy < DefaultAgentPolicy
  class Scope < Scope
    def resolve
      if context.can_access_others_planning?
        scope.where(organisation_id: current_organisation.id)
      else
        scope.joins(:agent).where(organisation_id: current_organisation.id, agents: { service_id: current_agent.service_id })
      end
    end
  end

  class DepartementScope < Scope
    def resolve
      if context.can_access_others_planning?
        scope.where(organisation_id: current_agent.organisations.pluck(:id))
      else
        scope.joins(:agent)
          .where(organisation_id: current_agent.organisations.pluck(:id))
          .where(agents: { service_id: current_agent.service_id })
      end
    end
  end
end
