class User::RdvPolicy < ApplicationPolicy
  def create?
    rdv_belongs_to_user_or_relatives?
  end

  def confirmation?
    rdv_belongs_to_user_or_relatives?
  end

  def cancel?
    @record.cancellable? && rdv_belongs_to_user_or_relatives?
  end

  def edit?
    rdv_belongs_to_user_or_relatives?
  end

  def update?
    rdv_belongs_to_user_or_relatives?
  end

  def index?
    rdv_belongs_to_user_or_relatives?
  end

  private

  def rdv_belongs_to_user_or_relatives?
    (@record.user_ids & @user.available_users_for_rdv.pluck(:id)).any?
  end

  class Scope < Scope
    def resolve
      scope.joins(:users).where(users: { id: @user.id }).or(User.joins(:users).where(users: { responsible_id: @user.id }))
    end
  end
end
