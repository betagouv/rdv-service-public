class User::RdvPolicy < ApplicationPolicy
  alias current_user pundit_user

  # rubocop:disable Style/ArrayIntersect

  def rdv_belongs_to_user_or_relatives?
    (record.user_ids & current_user.available_users_for_rdv.pluck(:id)).any?
  end

  # rubocop:enable Style/ArrayIntersect

  def index?
    !current_user.signed_in_with_invitation_token?
  end

  def new?
    return false if record.revoked?

    (record.collectif? && record.bookable_by_everyone_or_bookable_by_invited_users?) || rdv_belongs_to_user_or_relatives?
  end

  def create?
    return false if record.collectif?

    record.motif.bookable_by_everyone_or_bookable_by_invited_users? &&
      rdv_belongs_to_user_or_relatives?
  end

  def show?
    record.motif.visible? &&
      rdv_belongs_to_user_or_relatives? && (
      (record.collectif? && record.bookable_by_everyone_or_bookable_by_invited_users?) ||
      !current_user.signed_in_with_invitation_token? ||
      current_user.invited_for_rdv?(record)
    )
  end

  def cancel?
    show? && record.cancellable_by_user?
  end

  def edit?
    show? && record.editable_by_user?
  end

  def can_change_participants?
    record.motif.visible? &&
      !current_user.signed_in_with_invitation_token? &&
      current_user.participation_for(record).not_cancelled? &&
      !record.in_the_past?
  end

  alias creneaux? edit?
  alias update? edit?

  class Scope < Scope
    alias current_user pundit_user

    def resolve
      my_rdvs = scope
        .joins(:users)
        .where(users: { id: current_user.id })
        .or(
          User
            .joins(:users)
            .where(users: { responsible_id: current_user.id })
        )
        .visible

      bookable_rdv_collectifs = scope.where(id: scope.collectif.bookable_by_everyone_or_bookable_by_invited_users)

      scope.where(id: my_rdvs).or(bookable_rdv_collectifs).distinct
    end
  end
end
