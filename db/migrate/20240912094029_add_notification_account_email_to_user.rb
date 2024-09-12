class AddNotificationAccountEmailToUser < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :users, :notification_email, :string
    add_column :users, :account_email, :string
    add_index :users, :notification_email
    add_index :users, :account_email
  end
end
