class WebhookBuildAndSendJob < ApplicationJob
  queue_as :latency_30s

  discard_on(ActiveRecord::RecordNotFound) { |_job, error| Sentry.capture_exception(error) }

  def perform(record:, action:, webhook_endpoint_id:)
    payload = record.generate_webhook_payload(action)
    WebhookSendJob.new.perform(payload, webhook_endpoint_id)
  end
end
