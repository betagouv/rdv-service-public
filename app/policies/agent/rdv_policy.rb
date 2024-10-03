class Agent::RdvPolicy < ApplicationPolicy
  include CurrentAgentInPolicyConcern

  def create?
    true
  end
  alias new? create?

  def update?
    same_agent_or_has_access?
  end
  alias edit? update?
  alias status? update?

  # Pour le moment nous n'avons qu'un seul niveau d'accès à un RDV
  alias show? update?
  alias versions? show?

  def destroy?
    current_agent.access_level_in(@record.organisation) == AgentRole::ACCESS_LEVEL_ADMIN
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
    return true if current_agent.in?(@record.agents)

    case current_agent.access_level_in(@record.organisation)
    when AgentRole::ACCESS_LEVEL_ADMIN
      true
    when AgentRole::ACCESS_LEVEL_BASIC
      same_service? || current_agent.secretaire?
    else
      false
    end
  end

  class Scope < Scope
    include CurrentAgentInPolicyConcern

    def resolve
      my_rdvs = Rdv.joins(:agents_rdvs).where(agents_rdvs: { agent_id: current_agent.id })

      if current_agent.secretaire?
        rdvs_of_all_my_orgs = scope.where(organisation: current_agent.organisations)
        scope.where_id_in_subqueries([my_rdvs, rdvs_of_all_my_orgs])
      else
        rdv_of_my_admin_orgs = Rdv.where(organisation: current_agent.admin_orgs)
        rdv_of_my_basic_orgs = Rdv.where(organisation: current_agent.basic_orgs)
          .joins(:motif).where(motifs: { service: current_agent.services })
        scope.where_id_in_subqueries([my_rdvs, rdv_of_my_admin_orgs, rdv_of_my_basic_orgs])
      end
    end
  end

  class DepartementScope < Scope
  end
end
