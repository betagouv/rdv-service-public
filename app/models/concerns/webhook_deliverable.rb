# frozen_string_literal: true

# Hooks into :after_commit (:create and :update) and :around_destroy
# to create jobs for webhooks.
# The receiver must have a corresponding `<class>Blueprint` class.
module WebhookDeliverable
  extend ActiveSupport::Concern

  def generate_webhook_payload(action)
    # Reload attributes and associations from DB to ensure they are up to date.
    # We dont use #reload on self because some other parts
    # of the code rely on the state of the current object.
    record = self.class.unscoped.find(id)

    meta = {
      model: self.class.name,
      event: action,
      timestamp: Time.zone.now,
    }
    blueprint_class = "#{self.class.name}Blueprint".constantize
    blueprint_class.render(record, root: :data, meta: meta)
  end

  def generate_payload_and_send_webhook(action)
    subscribed_webhook_endpoints.each do |endpoint|
      WebhookJob.perform_later(generate_webhook_payload(action), endpoint.id)
    end
  end

  def generate_payload_and_send_webhook_for_destroy
    # Prépare les données à envoyer, avant de supprimer l'objet
    payloads = subscribed_webhook_endpoints.index_with do |_endpoint|
      generate_webhook_payload(:destroyed)
    end
    # Execute la suppression, après avoir construit les données à envoyer
    yield if block_given?
    payloads.each do |endpoint, payload|
      WebhookJob.perform_later(payload, endpoint.id)
    end
  end

  def subscribed_webhook_endpoints
    webhook_endpoints.select { _1.subscriptions.include?(self.class.name.underscore) }
  end

  included do
    # this attribute is used in some cases to explicitly disable webhooks callbacks
    # See: https://stackoverflow.com/a/38998807/2864020
    attr_accessor :skip_webhooks

    after_commit on: :create, unless: :skip_webhooks do
      generate_payload_and_send_webhook(:created)
    end

    after_commit on: :update, unless: :skip_webhooks do
      generate_payload_and_send_webhook(:updated)
    end

    around_destroy :generate_payload_and_send_webhook_for_destroy, unless: :skip_webhooks
  end
end
