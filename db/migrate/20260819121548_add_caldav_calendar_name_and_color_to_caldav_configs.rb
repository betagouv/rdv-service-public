class AddCaldavCalendarNameAndColorToCaldavConfigs < ActiveRecord::Migration[8.0]
  def change
    add_column :caldav_configs, :caldav_calendar_name, :string
    add_column :caldav_configs, :caldav_calendar_color, :string, limit: 7
  end
end
