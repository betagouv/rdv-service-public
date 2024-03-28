class Agent::MotifPolicy < ApplicationPolicy
  def update?
    admin_of_the_motif_organisation?
  end

  def new?
    current_agent.admin_orgs.any?
  end

  alias create? update?
  alias edit? update?
  alias destroy? update?
  alias versions? update?

  def show?
    return unless agent_role_in_motif_organisation

    current_agent.secretaire? || admin_of_the_motif_organisation? ||
      @record.service.in?(current_agent.services)
  end

  def bookable?
    @record.bookable_outside_of_organisation?
  end

  private

  alias current_agent pundit_user

  def admin_of_the_motif_organisation?
    return unless agent_role_in_motif_organisation

    agent_role_in_motif_organisation.access_level == AgentRole::ACCESS_LEVEL_ADMIN
  end

  def agent_role_in_motif_organisation
    @agent_role_in_motif_organisation ||= current_agent.roles.find_by(organisation_id: @record.organisation_ids)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.joins(:organisations).where(organisations: current_agent.organisation_ids)
    end

    alias current_agent pundit_user
  end
end
