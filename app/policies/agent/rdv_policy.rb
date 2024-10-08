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

  # Pour le moment nous n'avons qu'un seul niveau d'accès à un RDV,
  # qui permet à la fois de l'afficher et de le modifier
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
        rdvs_of_all_my_orgs = Rdv.where(organisation: current_agent.organisations)
        scope.where_id_in_subqueries([my_rdvs, rdvs_of_all_my_orgs])
      else
        # rdv_of_my_admin_orgs = Rdv.where(organisation: current_agent.admin_orgs)
        # rdv_of_my_basic_orgs = Rdv.where(organisation: current_agent.basic_orgs)
        #   .joins(:motif).where(motifs: { service: current_agent.services })
        # scope.where_id_in_subqueries([my_rdvs, rdv_of_my_admin_orgs, rdv_of_my_basic_orgs])

        scope.joins(:motif, :agents_rdvs)
          .joins("LEFT OUTER JOIN agent_roles as basic_agent_roles on basic_agent_roles.organisation_id = rdvs.organisation_id and basic_agent_roles.access_level = 'basic'")
          .joins("LEFT OUTER JOIN agent_roles as admin_agent_roles on admin_agent_roles.organisation_id = rdvs.organisation_id and admin_agent_roles.access_level = 'admin'")
          .where("agents_rdvs.agent_id = ? OR (basic_agent_roles.agent_id = ? AND motifs.service_id IN (?)) OR (admin_agent_roles.agent_id = ?)", current_agent.id, current_agent.id, current_agent.service_ids, current_agent.id)
      end
    end
  end

  class DepartementScope < Scope
  end
end
