class Agent::ExportPolicy < ApplicationPolicy
  alias current_agent pundit_user

  def download?
    record.agent == current_agent
  end

  class Scope < Scope
    alias current_agent pundit_user

    def resolve
      scope.where(agent: current_agent)
    end
  end
end
