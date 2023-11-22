class Agent::PlageOuverturePolicy < DefaultAgentPolicy
  class Scope < Scope
    def resolve
      if context.can_access_others_planning?
        scope.where(organisation: current_organisation)
      else
        scope.joins(:agent).where(organisation: current_organisation).merge(current_agent.confreres)
      end
    end
  end

  private

  def same_service?
    @record.agent.confrere_of?(current_agent)
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
