# frozen_string_literal: true

class AddTriggeringResourcesToWebhookEndpoints < ActiveRecord::Migration[6.0]
  def change
    add_column :webhook_endpoints, :subscriptions, :json, default: %w[rdv absence plage_ouverture]
  end
end
