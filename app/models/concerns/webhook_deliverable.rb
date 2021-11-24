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
    send_webhook(payload, action)
  end

  def generate_payload_and_send_webhook_for_destroy
    payload = generate_webhook_payload(:destroyed)
    yield if block_given?
    send_webhook(payload, :destroyed)
  end

  def send_webhook(payload, action)
    webhook_endpoints_for_action(action).each do |endpoint|
      WebhookJob.perform_later(payload, endpoint.id)
    end
  end

  def webhook_endpoints_for_action(action)
    webhook_endpoints.select do |webhook_endpoint|
      webhook_endpoint.subscribed_events[self.class.name.underscore]&.include?(action.to_s)
    end
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
