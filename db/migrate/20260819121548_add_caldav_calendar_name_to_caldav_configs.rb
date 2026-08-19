class AddCaldavCalendarNameToCaldavConfigs < ActiveRecord::Migration[8.0]
  def change
    add_column :caldav_configs, :caldav_calendar_name, :string
  end
end
