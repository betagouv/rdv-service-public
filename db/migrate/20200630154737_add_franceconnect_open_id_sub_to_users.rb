class AddFranceconnectOpenIdSubToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :franceconnect_openid_sub, :string
  end
end
