# frozen_string_literal: true

class Agent::PlageOuverturePolicy < DefaultAgentPolicy
  class Scope < Scope
    def resolve
      if context.can_access_others_planning?
        scope.where(organisation: current_organisation)
      else
        # TODO: parler de ça
        scope.joins(:agent).where(organisation: current_organisation).merge(Agent.in_services(current_agent.services))
      end
    end
  end

  class DepartementScope < Scope
    def resolve
      if context.can_access_others_planning?
        scope.where(organisation: current_agent.organisations)
      else
        scope.joins(:agent)
          .where(organisation: current_agent.organisations)
          .merge(Agent.in_services(current_agent.services)) # TODO: parler de ça
      end
    end
  end
end
