class CreateExternalCalendarSyncLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :external_calendar_sync_logs do |t| # rubocop:disable Rails/CreateTableWithTimestamps
      t.references :agent, foreign_key: true, null: false
      t.string :calendar_url, null: false
      t.boolean :successful
      t.text :text_logs, array: true, default: []
      t.datetime :started_at, null: false
      t.datetime :ended_at
    end
  end
end
