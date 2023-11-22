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

  def participation_token
    # For user invited with tokens, nil default for not invited users
    @notifier&.participations_tokens_by_user_id&.fetch(user.id, nil)
  end

  private

  def notify_update!(author)
    # We pass an empty array if notifications are disabled to avoid notifying other users
    user_to_notify = send_lifecycle_notifications? ? [user] : []

    if participation_cancelled?
      @notifier = Notifiers::RdvCancelled.new(rdv, author, user_to_notify)
    end

    if rdv_status_reloaded_from_cancelled?
      @notifier = Notifiers::RdvCreated.new(rdv, author, user_to_notify)
    end

    @notifier&.perform
  end

  def participation_cancelled?
    # Do not notify users for cancel statuses for previously cancelled rdv participation
    (status.in? Participation::CANCELLED_STATUSES) && !status_previously_was.in?(Participation::CANCELLED_STATUSES)
  end

  def rdv_status_reloaded_from_cancelled?
    status_previously_was.in?(Participation::CANCELLED_STATUSES) && status == "unknown"
  end
end
