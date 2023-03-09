# frozen_string_literal: true

class Notifiers::RdvUpcomingReminder < Notifiers::RdvBase
  protected

  def rdvs_users_to_notify
    @rdv.rdvs_users.not_cancelled.where(send_reminder_notification: true)
  end

  def notify_user_by_mail(user)
    user_mailer(user).rdv_upcoming_reminder.deliver_later(queue: :mailers_low, priority: -10)
  end

  def notify_user_by_sms(user)
    Users::RdvSms.rdv_upcoming_reminder(@rdv, user, @rdv_users_tokens_by_user_id[user.id]).deliver_later(queue: :sms_low, priority: -10)
  end
end
