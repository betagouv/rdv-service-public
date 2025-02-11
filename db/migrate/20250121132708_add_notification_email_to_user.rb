class AddNotificationEmailToUser < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :users, :notification_email, :string
    add_index :users, :notification_email,
              where: "notification_email IS NOT NULL",
              algorithm: :concurrently
  end
end
