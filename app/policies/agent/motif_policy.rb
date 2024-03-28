class Agent::MotifPolicy < ApplicationPolicy
  def update?
    admin_of_the_motif_organisation?
  end

  alias new? update?
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
      if current_agent.secretaire?
        scope.joins(:organisations).where(organisations: current_agent.organisation_ids)
      else
        return scope
        scope.joins(:organisations).where(organisations: current_agent.basic_orgs, service: current_agent.services)
          .or(scope.joins(:organisations).where(organisations: current_agent.admin_orgs))
      end
    end

    alias current_agent pundit_user
  end
end
