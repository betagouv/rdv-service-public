module Notifications::Rdv
  class RdvCancelledByAgentService < BaseService
    def notify_user(user)
      Users::RdvMailer.rdv_cancelled_by_agent(@rdv, user).deliver_later if user.email.present?
      TwilioSenderJob.perform_later(:rdv_cancelled, @rdv, user) if user.formatted_phone
    end
  end
end
