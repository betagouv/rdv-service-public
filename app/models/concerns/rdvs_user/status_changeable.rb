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
    @rdvs_user_token
  end

  def notify!(author)
    if rdv_user_cancelled? && user_valid_for_lifecycle_notifications?
      @rdvs_user_token = Notifiers::RdvCancelled.perform_with(rdv, author, [user])
    end
    if rdv_status_reloaded_from_cancelled? && user_valid_for_lifecycle_notifications?
      @rdvs_user_token = Notifiers::RdvCreated.perform_with(rdv, author, [user])
    end

    # Amine Fix on updatable, reminder for opening to public and setting up webhooks for rdv-insertion
    # self.skip_webhooks = false
  end

  def rdv_user_cancelled?
    (status.in? %w[excused revoked]) && !status_previously_was.in?(%w[excused revoked])
  end

  def rdv_status_reloaded_from_cancelled?
    status_previously_was.in?(%w[excused revoked]) && status == "unknown"
  end

  def user_valid_for_lifecycle_notifications?
    send_lifecycle_notifications == true
  end
end
