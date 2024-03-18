class Agent::MotifPolicy < ApplicationPolicy
  def self.agent_can_manage_motifs?(organisation, agent)
    agent.roles.find_by(organisation: organisation, access_level: AgentRole::ACCESS_LEVEL_ADMIN)
  end

  def self.agent_can_use_motifs?(organisation, agent)
    agent.roles.find_by(organisation: organisation)
  end

  def agent_can_manage_motifs?
    self.class.agent_can_manage_motifs?(@record.organisation_id, current_agent)
  end

  def agent_can_use_motifs?
    self.class.agent_can_use_motifs?(@record.organisation_id, current_agent)
  end

  alias new? agent_can_manage_motifs?
  alias duplicate? agent_can_manage_motifs?
  alias create? agent_can_manage_motifs?
  alias edit? agent_can_manage_motifs?
  alias update? agent_can_manage_motifs?
  alias destroy? agent_can_manage_motifs?
  alias versions? agent_can_manage_motifs?

  alias current_agent pundit_user

  def show?
    return unless agent_can_use_motifs?

    current_agent.secretaire? || agent_can_manage_motifs? ||
      @record.service.in?(current_agent.services)
  end

  def bookable?
    @record.bookable_outside_of_organisation?
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
