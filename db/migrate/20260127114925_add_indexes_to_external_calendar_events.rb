class AddIndexesToExternalCalendarEvents < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :external_calendar_events, %i[agent_id url], unique: true, algorithm: :concurrently
  end
end
