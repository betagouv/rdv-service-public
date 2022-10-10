# frozen_string_literal: true

module RdvsUser::StatusChangeable
  extend ActiveSupport::Concern

  def change_status(author, status)
    return if self.status == status

    RdvsUser.transaction do
      if update(status: status)
        notify!(author)
        true
      else
        false
      end
    end
  end

  def notify!(author)
    if rdv_cancelled? && user_valid_for_lifecycle_notifications?
      Notifiers::RdvCancelled.perform_with(rdv, author, [user])
    end
    if rdv_status_reloaded_from_cancelled? && user_valid_for_lifecycle_notifications?
      Notifiers::RdvCreated.perform_with(rdv, author, [user])
    end
  end

  def rdv_cancelled?
    previous_changes["status"]&.last.in? %w[excused revoked]
  end

  def rdv_status_reloaded_from_cancelled?
    status_previously_was.in?(%w[revoked excused]) && status == "unknown"
  end

  def user_valid_for_lifecycle_notifications?
    send_lifecycle_notifications == true
  end
end
