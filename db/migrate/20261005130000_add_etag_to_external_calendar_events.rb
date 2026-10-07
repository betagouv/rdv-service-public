class AddEtagToExternalCalendarEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :external_calendar_events, :etag, :string
  end
end
