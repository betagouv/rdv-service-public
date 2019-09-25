class Pro::FullSubscriptionPolicy < ApplicationPolicy
  def create?
    @user_or_pro.pro?
  end
end
