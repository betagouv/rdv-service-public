class User::RdvPolicy < ApplicationPolicy
  def create?
    (@record.user_ids & @user.available_users_for_rdv.pluck(:id)).any?
  end

  def confirmation?
    (@record.user_ids & @user.available_users_for_rdv.pluck(:id)).any?
  end

  class Scope < Scope
    def resolve
      scope.joins(:users).where(users: { id: @user.id }).or(User.joins(:users).where(users: { parent_id: @user.id }))
    end
  end
end
