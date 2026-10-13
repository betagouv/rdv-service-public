class AddVersionFlagToWebhooks < ActiveRecord::Migration[8.0]
  def change
    add_column :webhook_endpoints, :version, :string, default: "1", null: false
  end
end
