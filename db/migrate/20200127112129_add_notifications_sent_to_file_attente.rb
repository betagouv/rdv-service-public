class AddNotificationsSentToFileAttente < ActiveRecord::Migration[6.0]
  def change
    add_column :file_attentes, :notifications_sent, :integer, default: 0
    add_column :file_attentes, :last_creneau_sent_starts_at, :datetime
  end
end
