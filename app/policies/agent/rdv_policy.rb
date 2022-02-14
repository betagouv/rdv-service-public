# frozen_string_literal: true

class Agent::RdvPolicy < DefaultAgentPolicy
  def status?
    same_agent_or_has_access?
  end

  class Scope < Scope
    def resolve
      if context.can_access_others_planning?
        scope.where(organisation: current_organisation)
      else
        scope.joins(:motif).where(organisation: current_organisation, motifs: { service: current_agent.service })
      end
    end
  end

  class DepartementScope < Scope
    def resolve
      if context.can_access_others_planning?
        scope.where(organisation: current_agent.organisations)
      else
        scope.joins(:motif)
          .where(organisation: current_agent.organisations)
          .where(motifs: { service: current_agent.service })
      end
    end
  end
end
