class WebHookJob < ApplicationJob
  TIMEOUT = 10

  def perform(rdv, webhook)
    Typhoeus.post(
      webhook.endpoint,
      headers: { 'Content-Type' => 'application/json; charset=utf-8' },
      body: ActiveSupport::JSON.encode(rdv),
      timeout: TIMEOUT
    )
  end
end
