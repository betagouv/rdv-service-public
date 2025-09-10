class Agent::InstanceExportPolicy < ApplicationPolicy
  alias current_agent pundit_user

  def show?
    record.agent == current_agent
  end

  alias create? show?
  alias edit? show?
  alias update? show?

  class Scope < Scope
    alias current_agent pundit_user

    def resolve
      scope.where(agent: current_agent)
    end
  end
end
