module WebhookDeliverable
  extend ActiveSupport::Concern

  def generate_webhook_payload(action)
    meta = {
      model: self.class.name.underscore,
      event: action,
    }
    blueprint_class = "#{self.class.name}Blueprint".constantize
    blueprint_class.render(self, root: :data, meta: meta)
  end

  def generate_payload_and_send_webhook(action)
    payload = generate_webhook_payload(action)
    send_webhook(payload)
  end

  def send_webhook(payload)
    webhook_endpoints.each do |endpoint|
      WebhookJob.perform_later(payload, endpoint.id)
    end
  end

  included do
    after_commit on: :create do
      generate_payload_and_send_webhook(:created)
    end

    after_commit on: :update do
      generate_payload_and_send_webhook(:updated)
    end

    around_destroy :save_payload

    def save_payload
      payload = generate_webhook_payload(:destroyed)
      yield
      send_webhook(payload)
    end
  end
end
