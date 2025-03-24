class TriggerWebhookJob < ApplicationJob
  self.log_arguments = false

  def perform(webhook_endpoint_id)
    @webhook_endpoint = WebhookEndpoint.find(webhook_endpoint_id)
    @webhook_endpoint.trigger_for_all_subscribed_resources
  end
end
