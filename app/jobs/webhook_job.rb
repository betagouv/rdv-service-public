class WebhookJob < ApplicationJob
  class OutgoingWebhookError < StandardError; end

  TIMEOUT = 10

  queue_as :latency_30s
  include ExtendedRetryStrategyConcern

  discard_on(ActiveRecord::RecordNotFound) { |_job, error| Sentry.capture_exception(error) }

  # Pour éviter de fuiter des données personnelles dans les logs
  self.log_arguments = false

  #
  # Deux signatures possibles
  #
  # - perform(payload, webhook_endpoint_id)
  # - perform(record:, action:, webhook_endpoint_id:)
  #
  def perform(*args, **kwargs)
    if kwargs[:record]
      payload = kwargs[:record].generate_webhook_payload(kwargs[:action], event_occurred_at: kwargs[:event_occurred_at])
      webhook_endpoint_id = kwargs[:webhook_endpoint_id]
    else
      payload, webhook_endpoint_id = args
    end

    webhook_endpoint = WebhookEndpoint.find(webhook_endpoint_id)

    # Les envois de webhooks en env de dev sont notamment utilisés par RDV-I.
    return if Rails.env.development? && webhook_endpoint.target_url !~ /localhost/

    request = Typhoeus::Request.new(
      webhook_endpoint.target_url,
      method: :post,
      headers: {
        "Content-Type" => "application/json; charset=utf-8",
        "X-Lapin-Signature" => OpenSSL::HMAC.hexdigest("SHA256", webhook_endpoint.secret, payload),
      },
      body: payload,
      timeout: TIMEOUT
    )
    request.scrub_from_sentry_breadcrumbs = [:body]

    request.on_failure do |response|
      # On raise une erreur pour déclencher un retry, mais on ne l'enverra pas à Sentry

      if response.timed_out?
        raise OutgoingWebhookError, "HTTP Timeout, URL: #{webhook_endpoint.target_url}"
      elsif !WebhookJob.false_negative_from_drome?(response.body)
        raise OutgoingWebhookError, "HTTP #{response.code}, URL: #{webhook_endpoint.target_url}"
      end
    end

    request.on_success do |response|
      warn_on_html_response(response, webhook_endpoint)
    end

    request.run
  end

  def capture_sentry_warning_for_retry?(exception)
    # On considère que c'est aux systèmes qui reçoivent nos webhooks de surveiller les erreurs qu'ils ont au moment
    # de recevoir nos appels de webhooks.
    # On souhaite donc éviter de notifier sentry pour une erreur lors de l'appel.
    executions == 3 && !exception.is_a?(OutgoingWebhookError)
  end

  # La réponse de la Drôme est en JSON
  # mais leur serveur nous renvoie des erreurs
  # quand il n'arrive pas à faire son boulot.
  # Nous ne pouvons pas y faire grand chose,
  # c'est en général lié à une mise à jour
  # ou une suppression qui ne fonctionne pas
  #
  # Ce petit palliatif est là en attendant qu'ils
  # fassent évoluer leur système.
  def self.false_negative_from_drome?(body)
    body = JSON.parse(body)
    error_messages_from_drome = [
      /^Can't update appointment/,
      /^Appointment already deleted/,
      /^Appointment id doesn't exist/,
      /^Can't create appointment/,
    ]
    body["message"]&.match?(Regexp.union(error_messages_from_drome))
  rescue StandardError
    false
  end

  private

  # Le WAF du Pas-de-Calais bloque certaines requêtes et
  # renvoie une réponse en HTML avec un statut 200.
  def warn_on_html_response(response, webhook_endpoint)
    if response.body.include?("<html>")
      fingerprint = ["OutgoingWebhookError HTML", webhook_endpoint.target_url, response.code.to_s]
      Sentry.capture_message("HTML body in HTTP #{response.code} response in webhook to [#{webhook_endpoint.target_url}]", fingerprint: fingerprint)
    end
  end
end
