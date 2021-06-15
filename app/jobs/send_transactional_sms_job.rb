# frozen_string_literal: true

class SendTransactionalSmsJob < ApplicationJob
  queue_as :sms

  def perform(status, rdv_payload, user_id)
    TransactionalSms::Builder.with(OpenStruct.new(rdv_payload), User.find(user_id), status).send!
  end
end
