class SmsSenderJob < ApplicationJob
  def perform(status, rdv, user, options = {})
    SendTransactionalSmsService.perform_with(status, rdv, user, options) if Rails.env.production?
  end
end
