# frozen_string_literal: true

class User::RdvPolicy < ApplicationPolicy
  alias current_user pundit_user

  def rdv_belongs_to_user_or_relatives?
    (record.user_ids & current_user.available_users_for_rdv.pluck(:id)).any?
  end

  def index?
    !current_user.only_invited?
  end

  alias new? rdv_belongs_to_user_or_relatives?
  alias create? rdv_belongs_to_user_or_relatives?

  def show?
    rdv_belongs_to_user_or_relatives? && (!current_user.only_invited? || current_user.invited_for_rdv?(record))
  end

  def cancel?
    show? && record.cancellable?
  end

  def edit?
    show? && record.editable_by_user?
  end

  alias creneaux? edit?
  alias update? edit?

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
