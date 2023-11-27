class Agent::MotifPolicy < ApplicationPolicy
  def create?
    admin_of_the_motif_organisation?
  end

  def update?
    admin_of_the_motif_organisation?
  end

  def destroy?
    admin_of_the_motif_organisation?
  end

  def versions?
    admin_of_the_motif_organisation?
  end

  def show?
    admin_of_the_motif_organisation? || @record.service.in?(current_agent.services)
  end

  private

  def admin_of_the_motif_organisation?
    return unless agent_role_in_motif_organisation

    agent_role_in_motif_organisation.access_level == AgentRole::ACCESS_LEVEL_ADMIN
  end

  def agent_role_in_motif_organisation
    @agent_role_in_motif_organisation ||= current_agent.roles.find_by(organisation_id: @record.organisation_id)
  end

  class Scope < Scope
    def resolve
      if current_agent.secretaire?
        scope.where(organisation_id: agent.organisation_ids)
      else
        scope.where(organisation_id: agent.roles.where.not(access_level: :admin).organisation_ids, service: current_agent.services)
          .or(scope.where(organisation_id: agent.roles.where(access_level: :admin).organisation_ids))
      end
    end
  end
end
