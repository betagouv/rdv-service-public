class AddCaldavIncludeSensitiveDataToAgents < ActiveRecord::Migration[8.0]
  def change
    add_column :agents, :caldav_include_sensitive_data, :boolean, default: false, null: false
  end
end
