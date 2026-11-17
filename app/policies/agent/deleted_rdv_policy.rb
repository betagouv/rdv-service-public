# Réservé aux admins de l'organisation, par cohérence avec Agent::RdvPolicy#destroy? :
# seuls ceux qui peuvent supprimer un RDV peuvent consulter la liste des RDV supprimés.
class Agent::DeletedRdvPolicy < ApplicationPolicy
  include CurrentAgentInPolicyConcern

  def index?
    context.respond_to?(:organisation) && current_agent.admin_in_organisation?(context.organisation)
  end

  class Scope < Scope
    include CurrentAgentInPolicyConcern

    def resolve
      scope
        .joins("INNER JOIN agent_roles ON agent_roles.organisation_id = deleted_rdvs.organisation_id")
        .where(agent_roles: { agent_id: current_agent.id, access_level: AgentRole::ACCESS_LEVEL_ADMIN })
    end
  end
end
