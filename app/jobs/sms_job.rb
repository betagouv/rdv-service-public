class SmsJob < ApplicationJob
  queue_as :sms

  # Pour éviter de fuiter des données personnelles dans les logs
  self.log_arguments = false

  def perform(sender_name:, phone_number:, content:, territory_id:, receipt_params:)
    territory = Territory.find(territory_id)
    provider = ENV["FORCE_SMS_PROVIDER"].presence || territory&.sms_provider || ENV["DEFAULT_SMS_PROVIDER"].presence || :debug_logger
    api_key = territory&.sms_configuration || ENV["DEFAULT_SMS_PROVIDER_KEY"]

    SmsSender.perform_with(sender_name, phone_number, content, provider, api_key, receipt_params)
  end
end
