class AddAgentsInclusionConnectOpenIdSub < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :agents, :inclusion_connect_open_id_sub, :string
    add_index :agents, :inclusion_connect_open_id_sub, unique: true, where: "inclusion_connect_open_id_sub IS NOT NULL", algorithm: :concurrently
  end
end
