# frozen_string_literal: true

class OutgoingWebhookError < StandardError; end

class WebhookJob < ApplicationJob
  TIMEOUT = 10

  queue_as :webhook

  def perform(payload, webhook_endpoint_id)
    webhook_endpoint = WebhookEndpoint.find(webhook_endpoint_id)

    request = Typhoeus::Request.new(
      webhook_endpoint.target_url,
      method: :post,
      headers: {
        "Content-Type" => "application/json; charset=utf-8",
        "X-Lapin-Signature" => OpenSSL::HMAC.hexdigest("SHA256", webhook_endpoint.secret, payload)
      },
      body: payload,
      timeout: TIMEOUT
    )

    request.on_complete do |response|
      message = "Webhook Failure:\n"
      message += "url: #{webhook_endpoint.target_url}\n"
      message += "org: #{webhook_endpoint.organisation.name}\n"
      message += "response: #{response.code}\n"
      message += "body: #{response.body.force_encoding('UTF-8')[0...1000]}\n"
      raise OutgoingWebhookError, message unless response.success?
    end

    request.run
  end
end
