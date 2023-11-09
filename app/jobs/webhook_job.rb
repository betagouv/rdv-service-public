class OutgoingWebhookError < StandardError; end

class WebhookJob < ApplicationJob
  TIMEOUT = 10

  queue_as :webhook

  # Pour éviter de fuiter des données personnelles dans les logs
  self.log_arguments = false

  def perform(payload, webhook_endpoint_id)
    webhook_endpoint = WebhookEndpoint.find(webhook_endpoint_id)

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

    request.on_failure do |response|
      if response.timed_out?
        raise OutgoingWebhookError, "HTTP Timeout, URL: #{webhook_endpoint.target_url}"
      elsif !WebhookJob.false_negative_from_drome?(response.body)
        raise OutgoingWebhookError, "HTTP #{response.code}, URL: #{webhook_endpoint.target_url}"
      end
    end

    request.run
  end

  def log_failure_to_sentry?(_exception)
    # Pour limiter le bruit dans Sentry, on ne veut pas avoir de notification pour chaque retry.
    # On veut seulement :
    # - un premier avertissement assez rapide s'il y a un problème (4e essai)
    # - une notification pour le dernier essai, avant que le job passe en "abandonnés"
    executions == 4 || executions >= 10 || executions == MAX_ATTEMPTS
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
