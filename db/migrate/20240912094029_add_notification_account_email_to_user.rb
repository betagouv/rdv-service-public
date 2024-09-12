class AddNotificationAccountEmailToUser < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :users, :notification_email, :string
    add_column :users, :account_email, :string
    add_index :users, :notification_email, algorithm: :concurrently
    add_index :users, :account_email, algorithm: :concurrently, unique: true, where: "(account_email IS NOT NULL)"
  end
end
