# frozen_string_literal: true

class AddIndexToWebhooksEndpoints < ActiveRecord::Migration[7.0]
  def up
    add_index "webhook_endpoints", %w[organisation_id target_url], unique: true
  end

  def down
    remove_index "webhook_endpoints", %w[organisation_id target_url]
  end
end
