class AddCaldavDisconnectInProgressAtToAgents < ActiveRecord::Migration[8.0]
  def up
    add_column :agents, :caldav_disconnect_in_progress_at, :datetime

    # rubocop:disable Rails/SkipsModelValidations
    Agent.where(caldav_disconnect_in_progress: true).update_all(caldav_disconnect_in_progress_at: Time.current)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def down
    # rubocop:disable Rails/SkipsModelValidations
    Agent.where.not(caldav_disconnect_in_progress_at: nil).update_all(caldav_disconnect_in_progress: true)
    Agent.where(caldav_disconnect_in_progress_at: nil).update_all(caldav_disconnect_in_progress: false)
    # rubocop:enable Rails/SkipsModelValidations

    remove_column :agents, :caldav_disconnect_in_progress_at
  end
end
