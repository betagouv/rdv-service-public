# frozen_string_literal: true

module RdvsUser::StatusChangeable
  extend ActiveSupport::Concern

  def change_status(author, status)
    return if self.status == status

    RdvsUser.transaction do
      update(status: status) ? (notify!(author) || true) : false
    end
    # Notifiers are returning rdvs_user_token when a notif is sent or nil
  end

  def notify!(author)
    return nil unless user_valid_for_lifecycle_notifications?
    return Notifiers::RdvCancelled.perform_with(rdv, author, [user]) if rdv_user_cancelled?
    return Notifiers::RdvCreated.perform_with(rdv, author, [user]) if rdv_status_reloaded_from_cancelled?
    # Amine Fix on updatable, reminder for opening to public and setting up webhooks for rdv-insertion
    # self.skip_webhooks = false
  end

  def rdv_user_cancelled?
    # Do not notify users for cancel statuses for previously cancelled rdv participation
    (status.in? %w[excused revoked]) && !status_previously_was.in?(%w[excused revoked])
  end

  def rdv_status_reloaded_from_cancelled?
    status_previously_was.in?(%w[excused revoked]) && status == "unknown"
  end

  def user_valid_for_lifecycle_notifications?
    send_lifecycle_notifications == true
  end
end
