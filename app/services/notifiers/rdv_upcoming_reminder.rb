class Notifiers::RdvUpcomingReminder < Notifiers::RdvBase
  protected

  def participations_to_notify
    @rdv.participations.not_cancelled.where(send_reminder_notification: true)
  end

  def notify_user_by_mail(user)
    user_mailer(user).rdv_upcoming_reminder.deliver_later(queue: :mailers_low, priority: 10)
  end

  def notify_user_by_sms(user)
    Users::RdvSms.rdv_upcoming_reminder(@rdv, user, @participations_tokens_by_user_id[user.id]).deliver_later(queue: :sms_low, priority: 10)
  end
end
