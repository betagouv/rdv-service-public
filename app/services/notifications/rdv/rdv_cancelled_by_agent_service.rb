class Notifications::Rdv::RdvCancelledByAgentService < ::BaseService
  include Notifications::Rdv::BaseServiceConcern

  protected

  def notify_user(user)
    Users::RdvMailer.rdv_cancelled_by_agent(@rdv, user).deliver_later if user.email.present?
    SendTransactionalSmsJob.perform_later(:rdv_cancelled, @rdv.id, user.id) if user.formatted_phone
  end
end
