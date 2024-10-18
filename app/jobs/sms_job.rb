class SmsJob < ApplicationJob
  queue_as :sms

  # Pour éviter de fuiter des données personnelles dans les logs
  self.log_arguments = false

  discard_on(ActiveJob::DeserializationError) do |_job, error|
    # Si le RDV a été supprimé avant l'exécution du job (ou d’un retry)
    # C’est un comportement attendu, on ne veut pas retry ni être notifié sur Sentry
    next if error.cause.is_a?(ActiveRecord::RecordNotFound)

    # dans le cas encore jamais vu où la désérialisation échouerait pour d’autres raisons
    # il ne sert à rien de retry non plus, mais on aimerait en être notifié
    Sentry.capture_exception(error)
  end

  def perform(sender_name:, phone_number:, content:, territory_id:, receipt_params:)
    territory = Territory.find(territory_id)
    provider = ENV["FORCE_SMS_PROVIDER"].presence || territory&.sms_provider || ENV["DEFAULT_SMS_PROVIDER"].presence || :debug_logger
    api_key = territory&.sms_configuration || ENV["DEFAULT_SMS_PROVIDER_KEY"]

    SmsSender.perform_with(sender_name, phone_number, content, provider, api_key, receipt_params)
  end

  # Don't log first retries to Sentry, to prevent noise
  # on temporary unavailability of an external service.
  def capture_sentry_warning_for_retry?(_exception)
    super && executions > 2
  end
end
