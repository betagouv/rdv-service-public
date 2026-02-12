class WebhookBuildAndSendJob < ApplicationJob
  def perform(payload, webhook_endpoint_id)
    WebhookJob.perform_now(payload, webhook_endpoint_id)
  end
end
