class OutgoingWebhookError < StandardError; end

class WebhookJob < ApplicationJob
  TIMEOUT = 10

  queue_as :latency_30s
  include ExtendedRetryStrategyConcern

  discard_on(ActiveRecord::RecordNotFound) { |_job, error| Sentry.capture_exception(error) }

  # Pour éviter de fuiter des données personnelles dans les logs
  self.log_arguments = false

  before_perform { throw :abort if Rails.env.development? }

  #
  # Deux signatures possibles
  #
  # - perform(payload, webhook_endpoint_id)
  # - perform(record:, action:, webhook_endpoint_id:)
  #
  def perform(*args, **kwargs)
    if kwargs[:record]
      payload = kwargs[:record].generate_webhook_payload(kwargs[:action])
      webhook_endpoint_id = kwargs[:webhook_endpoint_id]
    else
      payload, webhook_endpoint_id = args
    end

    webhook_endpoint = WebhookEndpoint.find(webhook_endpoint_id)

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
      # Cela permet d'identifier singulièrement l'erreur selon l'URL et le code HTTP de la réponse
      Sentry.get_current_scope.set_fingerprint(["OutgoingWebhookError", webhook_endpoint.target_url, response.code.to_s])

      if response.timed_out?
        raise OutgoingWebhookError, "HTTP Timeout, URL: #{webhook_endpoint.target_url}"
      elsif !WebhookJob.false_negative_from_drome?(response.body)
        raise OutgoingWebhookError, "HTTP #{response.code}, URL: #{webhook_endpoint.target_url}"
      end
    end

    # Le WAF du Pas-de-Calais bloque certaines requêtes et
    # renvoie une réponse en HTML avec un statut 200.
    request.on_success do |response|
      if response.body.include?("<html>")
        fingerprint = ["OutgoingWebhookError HTML", webhook_endpoint.target_url, response.code.to_s]
        Sentry.capture_message("HTML body in HTTP #{response.code} response in webhook to [#{webhook_endpoint.target_url}]", fingerprint: fingerprint)
      end
    end

    request.run
  end

  def capture_sentry_warning_for_retry?(_exception)
    # Pour limiter le bruit dans Sentry, on ne veut pas avoir de notification pour chaque retry.
    # On veut seulement :
    # - un warning assez rapide s'il y a un problème (4e essai)
    # - une error pour le dernier essai, avant que le job passe en "abandonnés"
    # cette error est envoyée par sentry-rails nativement, qui ne passe pas par ce hook
    executions == 4
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
end
