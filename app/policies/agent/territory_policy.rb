class Agent::TerritoryPolicy < ApplicationPolicy
  alias context pundit_user
  delegate :agent, to: :context, prefix: :current # defines current_agent

  def agent_has_role_in_record_territory?
    current_agent.territorial_roles.pluck(:territory_id).include?(record.id)
  end

  alias show? agent_has_role_in_record_territory?
  alias update? agent_has_role_in_record_territory?

  class Scope < Scope
    alias context pundit_user
    delegate :agent, to: :context, prefix: :current # defines current_agent

    def resolve
      scope.with_agent(current_agent)
    end
  end
end
