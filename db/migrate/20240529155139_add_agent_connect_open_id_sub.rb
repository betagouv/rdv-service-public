class AddAgentConnectOpenIdSub < ActiveRecord::Migration[7.0]
  disable_ddl_transaction! # because CREATE INDEX CONCURRENTLY cannot run inside a transaction block

  def change
    add_column :agents, :agent_connect_open_id_sub, :string
    add_index :agents, :agent_connect_open_id_sub, unique: true, where: "agent_connect_open_id_sub IS NOT NULL", algorithm: :concurrently
  end
end
