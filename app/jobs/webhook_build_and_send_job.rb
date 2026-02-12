class WebhookBuildAndSendJob < ApplicationJob
  def perform(record:, action:, webhook_endpoint_id:)
    WebhookJob.perform_now(record:, action:, webhook_endpoint_id:)
  end
end
