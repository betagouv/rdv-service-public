class User::RdvPolicy < ApplicationPolicy
  def create?
    @record.user_ids.include?(@user.id)
  end

  def confirmation?
    @record.user_ids.include?(@user.id)
  end

  def cancel?
    @record.cancellable? && @record.user_ids.include?(@user.id)
  end

  class Scope < Scope
    def resolve
      scope.joins(:users).where(users: { id: @user.id }, cancelled_at: nil)
    end
  end
end
