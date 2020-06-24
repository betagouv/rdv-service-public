class Notifications::Rdv::RdvUpcomingReminderService < ::BaseService
  include Notifications::Rdv::BaseServiceConcern

  protected

  def notify_user(user)
    Users::RdvMailer.rdv_upcoming_reminder(@rdv, user).deliver_later if user.email.present?
    SmsSenderJob.perform_later(:reminder, @rdv.id, user.id) if user.formatted_phone
  end
end
