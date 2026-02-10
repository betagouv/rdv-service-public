# Hooks into :after_commit (:create and :update) and :around_destroy
# to create jobs for webhooks.
# The receiver must have a corresponding `<class>Blueprint` class.
module WebhookDeliverable
  extend ActiveSupport::Concern

  def generate_webhook_payload(action)
    meta = {
      model: self.class.name,
      event: action,
      webhook_reason: webhook_reason,
      timestamp: Time.zone.now,
    }
    blueprint_class = "#{self.class.name}Blueprint".constantize
    blueprint_class.render(self, root: :data, meta: meta)
  end

  def generate_payload_and_send_webhook(action)
    jobs = subscribed_webhook_endpoints.map do |endpoint|
      WebhookBuildAndSendJob.new(record: self, action:, webhook_endpoint_id: endpoint.id)
    end
    ActiveJob.perform_all_later(jobs)
  end

  def generate_payload_and_send_webhook_for_destroy
    if subscribed_webhook_endpoints.none?
      yield and return
    end

    # Prépare le payload, avant de supprimer l'objet
    payload = generate_webhook_payload(:destroyed)
    # Execute la suppression
    yield
    # Envoi le payload via jobs asynchrones
    jobs = subscribed_webhook_endpoints.map { |endpoint| WebhookSendJob.new(payload, endpoint.id) }
    ActiveJob.perform_all_later(jobs)
  end

  def subscribed_webhook_endpoints
    webhook_endpoints.select { _1.subscriptions.include?(self.class.name.underscore) }
  end

  included do
    # skip_webhooks is used in some cases to explicitly disable webhooks callbacks
    # See: https://stackoverflow.com/a/38998807/2864020
    # webhook_reason is used to give information on the trigger of the webhook (e.g. "rgpd" or "user")
    # See: https://github.com/betagouv/rdv-service-public/pull/3825
    attr_accessor :skip_webhooks, :webhook_reason

    after_commit on: :create, unless: :skip_webhooks do
      generate_payload_and_send_webhook(:created)
    end

    after_commit on: :update, unless: :skip_webhooks do
      generate_payload_and_send_webhook(:updated)
    end

    around_destroy :generate_payload_and_send_webhook_for_destroy, unless: :skip_webhooks
  end
end
