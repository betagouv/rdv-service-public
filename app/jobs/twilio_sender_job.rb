class TwilioSenderJob < ApplicationJob
  def perform(status, rdv, user)
    TwilioTextMessenger.new(status, rdv, user).send_sms
  end
end
