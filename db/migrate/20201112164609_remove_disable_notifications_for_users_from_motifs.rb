class RemoveDisableNotificationsForUsersFromMotifs < ActiveRecord::Migration[6.0]
  def change
    remove_column :motifs, :disable_notifications_for_users
  end
end
