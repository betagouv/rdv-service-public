class Notifications::Rdv::RdvUpcomingReminderService < ::BaseService
  include Notifications::Rdv::BaseServiceConcern

  protected

  def notify_user(user)
    Users::RdvMailer.rdv_upcoming_reminder(@rdv, user).deliver_later if user.email.present?
    TwilioSenderJob.perform_later(:reminder, @rdv, user) if user.formatted_phone
  end
end
