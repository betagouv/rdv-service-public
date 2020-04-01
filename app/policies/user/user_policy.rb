class User::UserPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(id: @user.id).or(User.where(responsible_id: @user.id))
    end
  end

  def create?
    user_is_responsible?
  end

  def update?
    @record.id == @user.id || user_is_responsible?
  end

  def destroy?
    @record.id == @user.id || user_is_responsible?
  end

  private

  def user_is_responsible?
    @record.responsible_id == @user.id
  end
end
