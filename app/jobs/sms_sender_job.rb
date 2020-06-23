class SmsSenderJob < ApplicationJob
  def perform(status, rdv, user, options = {})
    TransactionalSms.new(status, rdv, user, options).send_sms if Rails.env.production?
  end
end
