class CreateWebhookExecutions < ActiveRecord::Migration[7.1]
  def change
    create_table :webhook_executions do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.references :webhook_endpoint, null: false, foreign_key: true, index: false # on a plutôt un index composite
      t.date :day, null: false
      t.integer :http_code, null: false
      t.integer :counter, null: false, default: 0
    end

    add_index :webhook_executions, %i[webhook_endpoint_id day http_code], unique: true, name: "index_webhook_executions_composite"

    add_column :webhook_endpoints, :notification_email, :string
  end
end
