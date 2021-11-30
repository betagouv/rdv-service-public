# frozen_string_literal: true

class AddSubscriptionsToWebhookEndpoints < ActiveRecord::Migration[6.0]
  def change
    add_column :webhook_endpoints, :subscriptions, :string, array: true, default: %w[rdv absence plage_ouverture]
  end
end
