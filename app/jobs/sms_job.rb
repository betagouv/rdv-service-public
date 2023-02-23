# frozen_string_literal: true

class SmsJob < ApplicationJob
  queue_as :sms

  class InvalidMobilePhoneNumberError < StandardError; end

  def perform(sender_name:, phone_number:, content:, provider:, api_key:, receipt_params:) # rubocop:disable Metrics/ParameterLists
    raise InvalidMobilePhoneNumberError, "#{phone_number} is not a valid mobile phone number" unless PhoneNumberValidation.number_is_mobile?(phone_number)

    SmsSender.perform_with(sender_name, phone_number, content, provider, api_key, receipt_params)
  end
end
