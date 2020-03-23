class WebHookJob < ApplicationJob
  ENDPOINT_PREFIX = 'WEBHOOK_ENDPOINT_'.freeze
  TIMEOUT = 10

  def perform(rdv, organisme)
    endpoint = ENV["#{ENDPOINT_PREFIX}#{organisme}"]
    return unless endpoint

    Typhoeus.post(
      endpoint,
      headers: { 'Content-Type' => 'application/json; charset=utf-8' },
      body: ActiveSupport::JSON.encode(rdv),
      timeout: TIMEOUT
    )
  end
end
