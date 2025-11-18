module Participation::StatusChangeable
  extend ActiveSupport::Concern

  def change_status_and_notify(author, status)
    return if self.status == status

    Participation.transaction do
      if update(status: status)
        rdv.update_rdv_status_from_participation
        notify_update!(author)
        true
      else
        false
      end
    end

    rdv.generate_payload_and_send_webhook(:updated)
  end

  private

  def notify_update!(author)
    if participation_cancelled?
      # We pass an empty array if notifications are disabled to avoid notifying other users
      users_to_notify = send_lifecycle_notifications? ? [user] : []
      Notifiers::RdvCancelled.new(rdv, author, users_to_notify).perform
    elsif rdv_status_reloaded_from_cancelled?
      Notifiers::ParticipationCreated.new(participation: self, author:).perform
    end
  end

  def participation_cancelled?
    # Do not notify users for cancel statuses for previously cancelled rdv participation
    (status.in? Participation::CANCELLED_STATUSES) && !status_previously_was.in?(Participation::CANCELLED_STATUSES)
  end

  def rdv_status_reloaded_from_cancelled?
    status_previously_was.in?(Participation::CANCELLED_STATUSES) && status == "unknown"
  end
end
