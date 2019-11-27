class AddsSendNotificationToMotif < ActiveRecord::Migration[6.0]
  def change
    add_column :motifs, :send_notification, :boolean, default: true
  end
end
