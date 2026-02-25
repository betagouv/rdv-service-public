class RemoveCaldavDisconnectInProgressFromAgents < ActiveRecord::Migration[8.0]
  def change
    safety_assured do
      remove_column :agents, :caldav_disconnect_in_progress, :boolean, default: false, null: false
    end
  end
end
