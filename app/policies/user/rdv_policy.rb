# frozen_string_literal: true

class User::RdvPolicy < ApplicationPolicy
  alias current_user pundit_user

  def rdv_belongs_to_user_or_relatives?
    (record.user_ids & current_user.available_users_for_rdv.pluck(:id)).any?
  end

  alias new? rdv_belongs_to_user_or_relatives?
  alias show? rdv_belongs_to_user_or_relatives?
  alias create? rdv_belongs_to_user_or_relatives?

  # three next are used in creneaux controller when coming from file attentes
  alias index? rdv_belongs_to_user_or_relatives?
  alias edit? rdv_belongs_to_user_or_relatives?
  alias update? rdv_belongs_to_user_or_relatives?

  def cancel?
    record.cancellable? && rdv_belongs_to_user_or_relatives?
  end

  class Scope < Scope
    alias current_user pundit_user

    def resolve
      scope
        .joins(:users)
        .where(users: { id: current_user.id })
        .or(
          User
            .joins(:users)
            .where(users: { responsible_id: current_user.id })
        )
        .visible
    end
  end
end
