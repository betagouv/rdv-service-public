class AddUniqueIndexOnUsersFranceconnectOpenidSub < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    remove_index :users, :franceconnect_openid_sub
    add_index :users, :franceconnect_openid_sub, where: "franceconnect_openid_sub IS NOT NULL", unique: true, algorithm: :concurrently
  end

  def down
    remove_index :users, :franceconnect_openid_sub
    add_index :users, :franceconnect_openid_sub, where: "franceconnect_openid_sub IS NOT NULL", algorithm: :concurrently
  end
end
