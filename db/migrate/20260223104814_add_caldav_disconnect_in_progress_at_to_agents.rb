class AddCaldavDisconnectInProgressAtToAgents < ActiveRecord::Migration[8.0]
  def up
    add_column :agents, :caldav_disconnect_started_at, :datetime

    Agent.where(caldav_disconnect_in_progress: true).update_all(caldav_disconnect_started_at: Time.current)
  end

  def down
    Agent.where.not(caldav_disconnect_started_at: nil).update_all(caldav_disconnect_in_progress: true)
    Agent.where(caldav_disconnect_started_at: nil).update_all(caldav_disconnect_in_progress: false)

    remove_column :agents, :caldav_disconnect_started_at
  end
end
