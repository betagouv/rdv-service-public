class Agent::MotifPolicy < ApplicationPolicy
  def self.agent_can_manage_motif?(motif, agent)
    motif.organisation.in?(organisations_i_can_manage(agent))
  end

  def self.agent_can_use_motif?(motif, agent)
    return false unless motif.organisation.in?(agent.organisations)
    return true if motif.service.blank?

    agent.secretaire? ||
      agent_can_manage_motif?(motif, agent) ||
      motif.service_id.in?(agent.service_ids)
  end

  def self.organisations_i_can_manage(agent)
    agent.admin_orgs
  end

  def agent_can_manage_motif?
    self.class.agent_can_manage_motif?(motif, current_agent)
  end

  def agent_can_use_motif?
    self.class.agent_can_use_motif?(motif, current_agent)
  end

  alias show? agent_can_use_motif?
  alias new? agent_can_manage_motif?
  alias duplicate? agent_can_manage_motif?
  alias create? agent_can_manage_motif?
  alias edit? agent_can_manage_motif?
  alias update? agent_can_manage_motif?
  alias archive? agent_can_manage_motif?
  alias unarchive? agent_can_manage_motif?
  alias destroy? agent_can_manage_motif?
  alias versions? agent_can_manage_motif?

  alias open? agent_can_manage_motif?
  alias close? agent_can_manage_motif?

  alias current_agent pundit_user

  def bookable?
    motif.bookable_outside_of_organisation?
  end

  def motif
    @record
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if current_agent.secretaire?
        scope.where(organisation_id: current_agent.organisation_ids)
      else
        scope.where(organisation: current_agent.basic_orgs, service: (current_agent.services + [nil]))
          .or(scope.where(organisation: current_agent.admin_orgs))
      end
    end

    alias current_agent pundit_user
  end

  class ScopeForRdvsList < Scope
    # on veut permettre aux agents de filtrer sur les motifs d’autres services pour lesquels ils ont des RDV en binôme
    def resolve
      super.or(
        scope.where(
          organisation: current_agent.basic_orgs + current_agent.admin_orgs,
          id: motif_ids_from_other_services
        )
      )
    end

    private

    def motif_ids_from_other_services
      # L’exclusion des services de l’agent ci-dessous n’est pas nécessaire mais évite de retourner de nombreux motif ids dans cette sous-requête
      AgentsRdv.joins(rdv: [:motif])
        .where(agent: current_agent)
        .where.not(motifs: { service_id: current_agent.service_ids })
        .select("rdvs.motif_id")
    end
  end
end
