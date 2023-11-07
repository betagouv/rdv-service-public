class Agent::PlageOuverturePolicy < DefaultAgentPolicy
  def same_service?
    @record.agent.exactly_same_services_as?(current_agent)
  end

  class Scope < Scope
    def resolve
      if context.can_access_others_planning?
        scope.where(organisation: current_organisation)
      else
        scope.joins(:agent).where(organisation: current_organisation).merge(current_agent.confreres)
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
          .merge(current_agent.confreres)
      end
    end
  end
end
