class CreateExternalCalendarSyncExecutions < ActiveRecord::Migration[8.0]
  def change
    create_table :external_calendar_sync_executions do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.references :agent, foreign_key: true, null: false
      t.string :calendar_url, null: false
      t.boolean :successful
      t.datetime :started_at, null: false
      t.datetime :ended_at
    end

    create_table :external_calendar_sync_executions_logs do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.references :external_calendar_sync_execution, foreign_key: true, null: false
      t.text :message, null: false
      t.datetime :emitted_at, null: false
    end
  end
end
