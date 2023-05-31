# frozen_string_literal: true

class SmsJob < ApplicationJob
  queue_as :sms

  # Pour éviter de fuiter des données personnelles dans les logs
  self.log_arguments = false

  class InvalidMobilePhoneNumberError < StandardError; end

  def perform(sender_name:, phone_number:, content:, provider:, api_key:, receipt_params:) # rubocop:disable Metrics/ParameterLists
    raise InvalidMobilePhoneNumberError, "#{phone_number} is not a valid mobile phone number" unless PhoneNumberValidation.number_is_mobile?(phone_number)

    SmsSender.perform_with(sender_name, phone_number, content, provider, api_key, receipt_params)
  end

  # Don't log first failures to Sentry, to prevent noise
  # on temporary unavailability of an external service.
  def log_failure_to_sentry?(_exception)
    executions > 2
  end
end
