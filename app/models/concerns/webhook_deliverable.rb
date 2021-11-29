# frozen_string_literal: true

# Hooks into :after_commit (:create and :update) and :around_destroy
# to create jobs for webhooks.
# The receiver must
# * have a corresponding `<class>Blueprint` class.
# * have an :organisation
module WebhookDeliverable
  extend ActiveSupport::Concern

  def generate_webhook_payload(action)
    meta = {
      model: self.class.name,
      event: action,
      timestamp: Time.zone.now
    }
    blueprint_class = "#{self.class.name}Blueprint".constantize
    api_options = defined?(organisation) ? organisation.territory.api_options : {} # See issue #1657
    blueprint_class.render(self, root: :data, meta: meta, api_options: api_options)
  end

  def generate_payload_and_send_webhook(action)
    payload = generate_webhook_payload(action)
    send_webhook(payload)
  end

  def generate_payload_and_send_webhook_for_destroy
    payload = generate_webhook_payload(:destroyed)
    yield
    send_webhook(payload)
  end

  def send_webhook(payload)
    subscribed_webhook_endpoints.each do |endpoint|
      WebhookJob.perform_later(payload, endpoint.id)
    end
  end

  def subscribed_webhook_endpoints
    webhook_endpoints.select { _1.triggering_resources.include?(self.class.name.underscore) }
  end

  included do
    after_commit on: :create do
      generate_payload_and_send_webhook(:created)
    end

    after_commit on: :update do
      generate_payload_and_send_webhook(:updated)
    end

    around_destroy :generate_payload_and_send_webhook_for_destroy
  end
end
