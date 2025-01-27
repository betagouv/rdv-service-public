class CreateWebhookExecutions < ActiveRecord::Migration[7.1]
  def change
    create_table :webhook_executions do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.references :webhook_endpoint, foreign_key: true, index: true
      t.date :day
      t.integer :http_code
      t.integer :counter, default: 0
    end
  end
end
