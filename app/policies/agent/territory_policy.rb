class Agent::TerritoryPolicy < ApplicationPolicy
  alias context pundit_user
  delegate :agent, to: :context, prefix: :current # defines current_agent

  def agent_has_role_in_record_territory?
    current_agent.territorial_roles.exists?(territory_id: record.id)
  end

  alias show? agent_has_role_in_record_territory?
  alias update? agent_has_role_in_record_territory?
  alias edit? agent_has_role_in_record_territory?

  def show?
    agent_has_role_in_record_territory? ||
      allow_to_manage_teams? ||
      allow_to_manage_access_rights? ||
      allow_to_invite_agents?
  end

  class Scope < Scope
    alias context pundit_user
    delegate :agent, to: :context, prefix: :current # defines current_agent

    def resolve
      scope.joins(:roles).where(roles: { agent: current_agent })
    end
  end

  private

  def access_rights
    @access_rights ||= access_rights.where(territory: record)
  end

  def allow_to_manage_access_rights?
    access_rights&.allow_to_manage_access_rights?
  end

  def allow_to_invite_agents?
    access_rights&.allow_to_invite_agents?
  end

  def allow_to_manage_teams?
    access_rights&.allow_to_manage_teams?
  end
end
