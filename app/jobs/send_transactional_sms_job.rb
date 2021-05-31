# frozen_string_literal: true

class SendTransactionalSmsJob < ApplicationJob
  queue_as :sms

  def perform(status, rdv_id, user_id)
    TransactionalSms::Builder.with(Rdv.find(rdv_id), User.find(user_id), status).send!
  end
end
