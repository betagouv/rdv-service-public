class Agent::RdvPlanPolicy < ApplicationPolicy
  def create?
    true
  end
  alias new? create?
  alias edit? create?
  alias update? create?
end
