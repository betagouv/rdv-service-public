module Rdv::NotifiableConcern
  extend ActiveSupport::Concern

  included do
    # HACK: https://github.com/rails/rails/issues/29554#issuecomment-467837695
    after_create_commit -> { notify_rdv_created }
    after_update_commit -> { notify_rdv_date_updated }, if: -> { saved_change_to_starts_at? }
    after_update_commit -> { notify_rdv_cancelled }, if: -> { was_just_cancelled? }
  end

  def notify_rdv_created
    Notifications::Rdv::RdvCreatedService.perform_with(self)
  end

  def notify_rdv_date_updated
    Notifications::Rdv::RdvDateUpdatedService.perform_with(self)
  end

  def notify_rdv_cancelled
    Notifications::Rdv::RdvCancelledService.perform_with(self)
  end

  private

  def was_just_cancelled?
    [:unknown, :waiting, :seen].include?(status_before_last_save&.to_sym) &&
      [:excused, :notexcused].include?(status&.to_sym)
  end
end
