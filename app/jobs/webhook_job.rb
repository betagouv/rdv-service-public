# frozen_string_literal: true

class OutgoingWebhookError < StandardError; end

class WebhookJob < ApplicationJob
  TIMEOUT = 10
  MAX_ATTEMPTS = 10

  queue_as :webhook

  retry_on(OutgoingWebhookError, wait: :exponentially_longer, attempts: MAX_ATTEMPTS, queue: :webhook_retries)

  # Pour éviter de fuiter des données personnelles dans les logs
  self.log_arguments = false

  def perform(payload, webhook_endpoint_id)
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

    request.on_complete do |response|
      if !response.success? && !WebhookJob.false_negative_from_drome?(response.body)
        message = "Webhook-Failure (#{response.body.force_encoding('UTF-8')[0...1000]}):\n"
        message += "  url: #{webhook_endpoint.target_url}\n"
        message += "  org: #{webhook_endpoint.organisation.name}\n"
        message += "  response: #{response.code}"
        raise OutgoingWebhookError, message
      end
    end

    request.run
  end

  def log_failure_to_sentry?
    executions >= MAX_ATTEMPTS # only log last attempt to Sentry, to prevent noise
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
