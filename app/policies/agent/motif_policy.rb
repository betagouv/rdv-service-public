class Agent::MotifPolicy < ApplicationPolicy
  def self.agent_can_manage_motif?(motif, agent)
    motif.organisation.in?(organisations_i_can_manage(agent))
  end

  def self.agent_can_use_motif?(motif, agent)
    return false unless motif.organisation.in?(agent.organisations)

    agent.secretaire? ||
      agent_can_manage_motif?(motif, agent) ||
      motif.service.in?(agent.services)
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
  alias destroy? agent_can_manage_motif?
  alias versions? agent_can_manage_motif?

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
        scope.where(organisation: current_agent.basic_orgs, service: current_agent.services)
          .or(scope.where(organisation: current_agent.admin_orgs))
      end
    end

    alias current_agent pundit_user
  end
end
