class Notifications::Rdv::RdvUpdatedService < ::BaseService
  include Notifications::Rdv::BaseServiceConcern

  protected

  def notify_user(user)
    # TODO : it's weird that it uses the exact same notifications as for creations
    Users::RdvMailer.rdv_created(@rdv, user).deliver_later if user.email.present?
    SendTransactionalSmsJob.perform_later(:rdv_created, @rdv.id, user.id) if user.phone_number_formatted
  end
end
