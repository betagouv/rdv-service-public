class User::UserPolicy < ApplicationPolicy
  def create?
    user_is_parent?
  end

  def update?
    @record.id == @user.id || user_is_parent?
  end

  def destroy?
    @record.id == @user.id || user_is_parent?
  end

  private

  def user_is_parent?
    @record.parent_id == @user.id
  end
end
