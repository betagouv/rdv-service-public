# frozen_string_literal: true

module Rdv::SoftDeletable
  extend ActiveSupport::Concern

  included do
    alias_attribute :soft_deleted?, :deleted_at?
  end

  def soft_delete
    # disable the :updated webhook because we want to manually trigger a :destroyed webhook
    self.skip_webhooks = true
    return false unless update(deleted_at: Time.zone.now)

    generate_payload_and_send_webhook_for_destroy
    true
  end
end
