class Agent::RdvPolicy < DefaultAgentPolicy
  def status?
    same_agent_or_has_access?
  end

  def create?
    true
  end

  def destroy?
    current_agent.admin_in_organisation?(@record.organisation)
  end

  def self.explain(organisation, agent)
    explainations = if agent.admin_in_organisation?(organisation)
                      "En tant qu'administrateur de l'organisation, vous voyez les RDV de toute l'organisation #{organisation.name}."
                    elsif agent.secretaire?
                      "En tant que membre du service secrétariat, vous voyez les RDV de toute l'organisation #{organisation.name}."
                    else
                      "En tant qu'agent, vous voyez uniquement les RDV de vos services ayant lieu dans l'organisation #{organisation.name}."
                    end
    explainations += " Vous voyez également les RDV auxquels vous êtes associé"
    explainations
  end

  private

  def same_service?
    @record.motif.service.in?(current_agent.services)
  end

  def same_agent_or_has_access?
    if current_agent.in?(@record.agents)
      true
    elsif current_agent.in_organisation?(@record.organisation)
      same_service? || current_agent.secretaire? || current_agent.admin_in_organisation?(@record.organisation)
    else
      false
    end
  end

  class Scope < Scope
    def resolve
      organisation_scope = scope.where(organisation: current_agent.organisations)
      unless context.can_access_others_planning?
        organisation_scope = organisation_scope.joins(%i[motif agents_rdvs]).where(motifs: { service: current_agent.services })
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
          .where(motifs: { service: current_agent.services })
          .or(Rdv.where("agents_rdvs.agent_id": current_agent.id))
      end
    end
  end
end
