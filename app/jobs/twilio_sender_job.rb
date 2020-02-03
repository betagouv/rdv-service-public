class TwilioSenderJob < ApplicationJob
  def perform(status, rdv, user, options = {})
    TwilioTextMessenger.new(status, rdv, user, options).send_sms
  end
end
