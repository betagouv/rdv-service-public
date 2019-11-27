class SendNotificationRenameColumn < ActiveRecord::Migration[6.0]
  def change
    change_column_default :motifs, :send_notification, from: true, to: false
    rename_column :motifs, :send_notification, :disable_notifications_for_users
  end
end
