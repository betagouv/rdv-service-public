class Agent::FullSubscriptionPolicy < ApplicationPolicy
  def create?
    @user_or_agent.agent?
  end
end
