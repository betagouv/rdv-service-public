class SmsJob < ApplicationJob
  queue_as :sms

  # Pour éviter de fuiter des données personnelles dans les logs
  self.log_arguments = false

  def perform(*_args, **kwargs)
    sender_name = kwargs[:sender_name]
    phone_number = kwargs[:phone_number]
    content = kwargs[:content]
    receipt_params = kwargs[:receipt_params]

    # TODO: retirer la branche else 2 semaines après le merge (elle gère les args des anciens jobs)
    if kwargs[:territory_id]
      territory = Territory.find(kwargs[:territory_id])
      provider = territory&.sms_provider || ENV["DEFAULT_SMS_PROVIDER"].presence || :debug_logger
      api_key = territory&.sms_configuration || ENV["DEFAULT_SMS_PROVIDER_KEY"]
    else
      provider = kwargs[:provider]
      api_key = kwargs[:api_key]
    end

    SmsSender.perform_with(sender_name, phone_number, content, provider, api_key, receipt_params)
  end

  # Don't log first failures to Sentry, to prevent noise
  # on temporary unavailability of an external service.
  def log_failure_to_sentry?(_exception)
    executions > 2
  end
end
