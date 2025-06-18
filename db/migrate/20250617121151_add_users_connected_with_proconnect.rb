class AddUsersConnectedWithProconnect < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :pro_connect_openid_sub, :string
  end
end
