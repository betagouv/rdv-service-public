class Agent::RdvPlanPolicy < ApplicationPolicy
  def create?
    pundit_user == record.planning_agent
  end
  alias new? create?
  alias edit? create?
  alias update? create?
  alias show? create?

  class Scope
    def resolve
      scope.where(planning_agent: pundit_user)
    end
  end
end
