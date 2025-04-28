class AddNotificationEmailToUser < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :users, :notification_email, :string, comment: "Used for notifications only, multiple users can share the same email notification address"
    add_index :users, :notification_email,
              where: "notification_email IS NOT NULL",
              algorithm: :concurrently
  end
end
