class User::ParticipationPolicy < ApplicationPolicy
  alias current_user pundit_user

  def participation_belongs_to_user_or_relatives?
    current_user.available_users_for_rdv.pluck(:id).include? record.user_id
  end

  def create?
    return false if record.rdv.revoked?

    participation_belongs_to_user_or_relatives?
  end

  def cancel?
    participation_belongs_to_user_or_relatives? && record.cancellable_by_user?
  end

  class Scope < Scope
    alias current_user pundit_user

    def resolve
      scope
        .where(user_id: current_user.available_users_for_rdv.pluck(:id))
    end
  end
end
