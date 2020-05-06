module Notifications::Rdv
  class RdvCreatedService < BaseService
    protected

    def notify_user(user)
      Users::RdvMailer.rdv_created(@rdv, user).deliver_later if user.email.present?
      TwilioSenderJob.perform_later(:rdv_created, @rdv, user) if user.formatted_phone
    end
  end
end
