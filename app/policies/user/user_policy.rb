class User::UserPolicy < ApplicationPolicy
  def create?
    is_parent?
  end

  def update?
    @record.id == @user.id || is_parent?
  end

  def destroy?
    @record.id == @user.id || is_parent?
  end

  private

  def is_parent?
    @record.parent_id == @user.id
  end
end
