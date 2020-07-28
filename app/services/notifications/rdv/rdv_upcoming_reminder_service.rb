class Notifications::Rdv::RdvUpcomingReminderService < ::BaseService
  include Notifications::Rdv::BaseServiceConcern

  protected

  def notify_user(user)
    Users::RdvMailer.rdv_upcoming_reminder(@rdv, user).deliver_later if user.email.present?
    SendTransactionalSmsJob.perform_later(:reminder, @rdv.id, user.id) if user.phone_number_formatted
  end
end
