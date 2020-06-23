class SmsSenderJob < ApplicationJob
  def perform(status, rdv, user, options = {})
    SendTransactionalSmsService.new(status, rdv, user, options).perform if Rails.env.production?
  end
end
