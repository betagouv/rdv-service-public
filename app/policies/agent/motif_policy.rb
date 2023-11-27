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
    admin_of_the_motif_organisation? || @record.service.in?(pundit_user.services)
  end

  private

  def admin_of_the_motif_organisation?
    return unless agent_role_in_motif_organisation

    agent_role_in_motif_organisation.access_level == AgentRole::ACCESS_LEVEL_ADMIN
  end

  def agent_role_in_motif_organisation
    @agent_role_in_motif_organisation ||= pundit_user.roles.find_by(organisation_id: @record.organisation_id)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if pundit_user.secretaire?
        scope.where(organisation_id: agent.organisation_ids)
      else
        scope.where(organisation_id: agent.roles.where.not(access_level: :admin).organisation_ids, service: pundit_user.services)
          .or(scope.where(organisation_id: agent.roles.where(access_level: :admin).organisation_ids))
      end
    end
  end
end
