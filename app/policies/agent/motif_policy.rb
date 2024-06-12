class Agent::MotifPolicy < ApplicationPolicy
  def self.agent_can_manage_motif?(motif, agent)
    motif.organisation.in?(organisations_i_can_manage(agent))
  end

  def self.agent_can_use_motif?(motif, agent)
    motif.in?(UseScope.motifs_i_can_use(agent))
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

  class ManageScope < Scope
    def self.motifs_i_can_manage(agent)
      orgs_of_territories_i_admin = Organisation.where(territory: agent.territories)
      orgs_i_admin = Organisation.where(id: agent.roles.access_level_admin.select(:organisation_id))

      Motif.where(organisation: orgs_of_territories_i_admin.or(orgs_i_admin))
    end

    def resolve
      scope.merge(self.class.motifs_i_can_manage(current_agent))
    end
    alias current_agent pundit_user
  end

  class UseScope < Scope
    def self.motifs_i_can_use(agent)
      if agent.secretaire?
        Motif.where(organisation: agent.organisations)
      else
        Motif.where(organisation: agent.basic_orgs, service: agent.services)
      end.or(ManageScope.motifs_i_can_manage(agent))
    end

    def resolve
      self.class.motifs_i_can_use(current_agent).merge(scope)
    end
    alias current_agent pundit_user
  end
end
