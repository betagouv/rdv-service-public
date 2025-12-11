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
      Notifiers::ParticipationCancelled.new(participation: self, author:).perform
    elsif participation_status_reloaded_from_cancelled?
      Notifiers::ParticipationCreated.new(participation: self, author:).perform
    end
  end

  def participation_cancelled?
    # Do not notify users for cancel statuses for previously cancelled rdv participation
    (status.in? Participation::CANCELLED_STATUSES) && !status_previously_was.in?(Participation::CANCELLED_STATUSES)
  end

  def participation_status_reloaded_from_cancelled?
    status_previously_was.in?(Participation::CANCELLED_STATUSES) && status == "unknown"
  end
end
