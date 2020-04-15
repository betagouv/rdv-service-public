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

      before_destroy prepend: true do
        deliver_webhook(:destroyed)
      end
    end
  end
end
