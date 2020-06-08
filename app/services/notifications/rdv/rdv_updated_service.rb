class Notifications::Rdv::RdvUpdatedService < ::BaseService
  include Notifications::Rdv::BaseServiceConcern

  protected

  def notify_user(user)
    # TODO : it's weird that it uses the exact same notifications as for creations
    Users::RdvMailer.rdv_created(@rdv, user).deliver_later if user.email.present?
    TwilioSenderJob.perform_later(:rdv_created, @rdv, user) if user.formatted_phone
  end
end
