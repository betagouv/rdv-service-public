class Agent::DeletedRdvPolicy < ApplicationPolicy
  include CurrentAgentInPolicyConcern

  def index?
    true # le filtrage se fait dans le Scope
  end

  # Mêmes règles de visibilité que pour les RDV : admins et agents d'accueil voient toute l'organisation,
  # les autres agents voient les RDV auxquels ils participaient ou ceux de leurs services.
  class Scope < Scope
    include CurrentAgentInPolicyConcern

    def resolve
      scope
        .joins("INNER JOIN agent_roles ON agent_roles.organisation_id = deleted_rdvs.organisation_id")
        .joins("LEFT OUTER JOIN motifs ON motifs.id = deleted_rdvs.motif_id")
        .where(agent_roles: { agent_id: current_agent.id })
        .where(
          "? = ANY(deleted_rdvs.agent_ids)
            OR motifs.service_id IS NULL
            OR (motifs.service_id IN (?) AND agent_roles.access_level = 'basic')
            OR agent_roles.access_level = 'admin' OR agent_roles.agent_accueil = true",
          current_agent.id, current_agent.service_ids.presence || [0]
        )
    end
  end
end
