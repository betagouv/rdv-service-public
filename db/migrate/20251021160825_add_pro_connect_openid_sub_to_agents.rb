class AddProConnectOpenidSubToAgents < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_column :agents, :pro_connect_openid_sub, :string
    add_index :agents, :pro_connect_openid_sub, algorithm: :concurrently, where: "pro_connect_openid_sub IS NOT NULL"
  end
end
