class WebHookJob < ApplicationJob
  ENDPOINT_PREFIX = 'WEBHOOK_ENDPOINT_'.freeze
  TIMEOUT = 10

  def perform(rdv, departement)
    endpoint = ENV["#{ENDPOINT_PREFIX}#{departement}"]
    return unless endpoint

    Typhoeus.post(
      endpoint,
      headers: { 'Content-Type' => 'application/json; charset=utf-8' },
      body: ActiveSupport::JSON.encode(rdv),
      timeout: TIMEOUT
    )
  end
end
