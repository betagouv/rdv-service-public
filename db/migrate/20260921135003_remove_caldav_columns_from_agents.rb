class RemoveCaldavColumnsFromAgents < ActiveRecord::Migration[8.0]
  def change
    safety_assured do
      remove_column :agents, :caldav_agenda_url, :string
      remove_column :agents, :caldav_username, :string
      remove_column :agents, :caldav_password, :string
      remove_column :agents, :caldav_sync_token, :string
      remove_column :agents, :caldav_disconnect_started_at, :datetime
      remove_column :agents, :caldav_include_sensitive_data, :boolean
    end
  end
end
