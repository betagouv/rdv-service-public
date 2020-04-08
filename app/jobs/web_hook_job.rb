class WebHookJob < ApplicationJob
  TIMEOUT = 10

  def perform(rdv, webhook)
    body = ActiveSupport::JSON.encode(rdv)
    Typhoeus.post(
      webhook.endpoint,
      headers: {
        'Content-Type' => 'application/json; charset=utf-8',
        'X-Lapin-Signature' => OpenSSL::HMAC.hexdigest("SHA256", "secret", body)
      },
      body: body,
      timeout: TIMEOUT
    )
  end
end
