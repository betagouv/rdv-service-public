class AddDisplayExtendedHoursToAgents < ActiveRecord::Migration[8.0]
  def change
    add_column :agents, :display_extended_hours, :boolean, null: false, default: false
  end
end
