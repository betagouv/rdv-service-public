class Agent::MotifPolicy < ApplicationPolicy
  def new?
    update?
  end

  def create?
    update?
  end

  def edit?
    update?
  end

  def update?
    admin_of_the_motif_organisation?
  end

  def destroy?
    update?
  end

  def versions?
    update?
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
        scope.where(organisation_id: pundit_user.organisation_ids)
      else
        scope.where(organisation_id: pundit_user.roles.where.not(access_level: :admin).pluck("organisation_id"), service: pundit_user.services)
          .or(scope.where(organisation_id: pundit_user.roles.where(access_level: :admin).pluck("organisation_id")))
      end
    end
  end
end
