class User::RdvPolicy < ApplicationPolicy
  def change_creneau?
    rdv_belongs_to_user_or_children?
  end

  def create?
    rdv_belongs_to_user_or_children?
  end

  def confirmation?
    rdv_belongs_to_user_or_children?
  end

  def cancel?
    @record.cancellable? && rdv_belongs_to_user_or_children?
  end

  private

  def rdv_belongs_to_user_or_children?
    (@record.user_ids & @user.available_users_for_rdv.pluck(:id)).any?
  end

  class Scope < Scope
    def resolve
      scope.joins(:users).where(users: { id: @user.id }).or(User.joins(:users).where(users: { parent_id: @user.id }))
    end
  end
end
