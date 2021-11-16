# frozen_string_literal: true

class Notifications::Rdv::RdvUpcomingReminderService < ::BaseService
  protected

  def notify_user_by_mail(user)
    Users::RdvMailer.rdv_upcoming_reminder(@rdv.payload(nil, user), user).deliver_later
    @rdv.events.create!(event_type: RdvEvent::TYPE_NOTIFICATION_MAIL, event_name: :upcoming_reminder)
  end

  def notify_user_by_sms(user)
    Users::RdvSms.rdv_upcoming_reminder(@rdv, user).deliver_later
    @rdv.events.create!(event_type: RdvEvent::TYPE_NOTIFICATION_SMS, event_name: :upcoming_reminder)
  end
end
