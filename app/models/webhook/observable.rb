module Webhook
  module Observable
    extend ActiveSupport::Concern
    include Webhook::Delivery

    included do
      after_commit on: :create do
        deliver_webhook(:created)
      end

      after_commit on: :update do
        deliver_webhook(:updated)
      end

      around_destroy :save_payload

      def save_payload
        payload = webhook_data
        yield
        deliver_webhook(:destroyed, payload)
      end
    end
  end
end
