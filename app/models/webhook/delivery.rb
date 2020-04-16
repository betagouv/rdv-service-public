module Webhook
  module Delivery
    extend ActiveSupport::Concern

    def generate_webhook_payload(action)
      meta = {
        model: self.class.name.underscore,
        event: action,
      }
      webhook_renderer.render(self, root: :data, meta: meta)
    end

    def deliver_webhook(action)
      payload = generate_webhook_payload(action)
      send_webhook(payload)
    end

    def send_webhook(payload)
      webhook_endpoints.each do |endpoint|
        WebhookJob.perform_later(payload, endpoint.id)
      end
    end
  end
end
