class AddAmiFranceConnectHashToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :ami_france_connect_hash, :string
  end
end
