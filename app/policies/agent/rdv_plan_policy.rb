class Agent::RdvPlanPolicy < ApplicationPolicy
  def create?
    pundit_user == record.planning_agent
  end
  alias show? create?

  class Scope < Scope
    def resolve
      scope.where(planning_agent: pundit_user)
    end
  end
end
