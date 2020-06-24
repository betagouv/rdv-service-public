class SendTransactionalSmsJob < ApplicationJob
  def perform(status, rdv_id, user_id, options = {})
    rdv = Rdv.find(rdv_id)
    user = Rdv.find(user_id)
    SendTransactionalSmsService.perform_with(status, rdv, user, options) if Rails.env.production?
  end
end
