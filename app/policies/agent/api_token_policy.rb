class Agent::ApiTokenPolicy < ApplicationPolicy
  def index? = true
  def new? = true
  def create? = true

  def destroy?
    record.agent == pundit_user.agent
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(agent: pundit_user.agent)
    end
  end
end
