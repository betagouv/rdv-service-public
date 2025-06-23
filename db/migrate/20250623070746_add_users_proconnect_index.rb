class AddUsersProconnectIndex < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :users, :pro_connect_openid_sub, algorithm: :concurrently, unique: true, where: "pro_connect_openid_sub IS NOT NULL"
  end
end
