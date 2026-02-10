class WebhookBuildAndSendJob < ApplicationJob
  queue_as :latency_30s

  def perform(record:, action:, webhook_endpoint_id:)
    payload = record.generate_webhook_payload(action)
    WebhookSendJob.perform_later(payload, webhook_endpoint_id)
  end
end
