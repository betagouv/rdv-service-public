class CreateApiCalls < ActiveRecord::Migration[7.0]
  def change
    create_table :api_calls do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.datetime :received_at, null: false
      t.jsonb :raw_http, null: false
      t.string :controller_name, null: false
      t.string :action_name, null: false
      t.bigint :agent_id, null: false
    end

    add_foreign_key :api_calls, :agents, validate: false
  end
end
