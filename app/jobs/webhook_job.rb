class WebhookJob < ApplicationJob
  TIMEOUT = 10

  def perform(rdv, webhook_endpoint_id)
    webhook_endpoint = WebhookEndpoint.find(webhook_endpoint_id)

    body = ActiveSupport::JSON.encode(rdv)
    Typhoeus.post(
      webhook_endpoint.target_url,
      headers: {
        'Content-Type' => 'application/json; charset=utf-8',
        'X-Lapin-Signature' => OpenSSL::HMAC.hexdigest("SHA256", webhook_endpoint.secret, body),
      },
      body: body,
      timeout: TIMEOUT
    )
  end
end
