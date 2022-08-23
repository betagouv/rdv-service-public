# frozen_string_literal: true

class SmsJob < ApplicationJob
  queue_as do
    arguments.first
  end

  class InvalidMobilePhoneNumberError < StandardError; end

  def perform(_queue, sender_name:, phone_number:, content:, tags:, provider:, key:, receipt_params:)
    raise InvalidMobilePhoneNumberError, "#{phone_number} is not a valid mobile phone number" unless PhoneNumberValidation.number_is_mobile?(phone_number)

    SmsSender.perform_with(sender_name, phone_number, content, tags, provider, key, receipt_params)
  end
end
