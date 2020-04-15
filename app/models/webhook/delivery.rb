module Webhook
  module Delivery
    extend ActiveSupport::Concern

    def deliver_webhook(action)
      payload = {
        model: self.class.name.underscore,
        event: action,
        data: webhook_data,
      }.as_json

      webhook_endpoints.each do |endpoint|
        WebhookJob.perform_later(payload, endpoint.id)
      end
    end
  end
end
