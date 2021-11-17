# frozen_string_literal: true

class AddSubscribedEventsToWebhookEndpoints < ActiveRecord::Migration[6.0]
  def change
    add_column :webhook_endpoints, :subscribed_events, :json, default: {
      "rdv" => %w[created updated destroyed],
      "absence" => %w[created updated destroyed],
      "plage_ouverture" => %w[created updated destroyed]
    }
  end
end
