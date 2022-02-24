# frozen_string_literal: true

class Notifiers::RdvUpcomingReminder < Notifiers::RdvBase
  protected

  def rdvs_users_to_notify
    @rdv.rdvs_users.where(send_reminder_notification: true)
  end

  def notify_user_by_mail(user)
    Users::RdvMailer.rdv_upcoming_reminder(@rdv.payload(nil, user), user, @tokens_by_user_id[user.id]).deliver_later
    @rdv.events.create!(event_type: RdvEvent::TYPE_NOTIFICATION_MAIL, event_name: :upcoming_reminder)
  end

  def notify_user_by_sms(user)
    Users::RdvSms.rdv_upcoming_reminder(@rdv, user, @tokens_by_user_id[user.id]).deliver_later
    @rdv.events.create!(event_type: RdvEvent::TYPE_NOTIFICATION_SMS, event_name: :upcoming_reminder)
  end
end
