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

  def self.explain(organisation, agent)
    explainations = if agent.admin_in_organisation?(organisation)
                      "En tant qu'administrateur de l'organisation, vous voyez les RDV de toute l'organisation #{organisation.name}."
                    elsif agent.service.secretariat?
                      "En tant que membre du service secrétariat, vous voyez les RDV de toute l'organisation #{organisation.name}."
                    else
                      "En tant qu'agent, Vous voyez uniquement les RDV de votre service ayant lieu dans l'organisation #{organisation.name}."
                    end
    explainations << " Vous voyez également les RDV auxquels vous êtes associé"
    explainations
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
