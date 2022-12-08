# frozen_string_literal: true

class Agent::RdvPolicy < DefaultAgentPolicy
  def status?
    same_agent_or_has_access?
  end

  def create?
    true
  end

  def destroy?
    admin_and_same_org?
  end

  class Scope < Scope
    def resolve
      organisation_scope = scope.where(organisation: current_agent.organisations)
      unless context.can_access_others_planning?
        organisation_scope = organisation_scope.joins(%i[motif agents_rdvs]).where(motifs: { service: current_agent.service })
          .or(Rdv.where("agents_rdvs.agent_id": current_agent.id))
      end
      organisation_scope
    end
  end

  class DepartementScope < Scope
    def resolve
      if context.can_access_others_planning?
        scope.where(organisation: current_agent.organisations)
      else
        scope.joins(%i[motif agents_rdvs])
          .where(organisation: current_agent.organisations)
          .where(motifs: { service: current_agent.service })
          .or(Rdv.where("agents_rdvs.agent_id": current_agent.id))
      end
    end
  end
end
