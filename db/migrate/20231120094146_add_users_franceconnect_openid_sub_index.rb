class AddUsersFranceconnectOpenidSubIndex < ActiveRecord::Migration[7.0]
  def change
    add_index :users, :franceconnect_openid_sub
  end
end
