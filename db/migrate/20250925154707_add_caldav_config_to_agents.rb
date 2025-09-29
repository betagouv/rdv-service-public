class AddCaldavConfigToAgents < ActiveRecord::Migration[7.2]
  def change
    add_column :agents, :caldav_agenda_url, :string
    add_column :agents, :caldav_username, :string
    add_column :agents, :caldav_password, :string
  end
end
