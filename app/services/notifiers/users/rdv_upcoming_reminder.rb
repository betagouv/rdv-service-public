class Notifiers::Users::RdvUpcomingReminder < BaseService
  def initialize(rdv)
    @rdv = rdv
  end

  def perform
    return if @rdv.starts_at < Time.zone.now

    notify_users_by_mail
    notify_users_by_sms
  end

  protected

  def users_to_notify
    participations_to_notify.map(&:user).map(&:user_to_notify).uniq
  end

  def participations_to_notify
    @rdv.participations.not_cancelled.where(send_reminder_notification: true)
  end

  def notify_users_by_mail
    users_to_notify.select(&:notifiable_by_email?).each do |user|
      Users::RdvMailer.with(rdv: @rdv, user:).rdv_upcoming_reminder.deliver_later(queue: :latency_5m)
    end
  end

  def notify_users_by_sms
    users_to_notify.select(&:notifiable_by_sms?).each do |user|
      Users::RdvSms.rdv_upcoming_reminder(@rdv, user).deliver_later(queue: :latency_5m)
    end
  end
end
