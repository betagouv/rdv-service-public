class AddAgentConnectedWithAgentConnect < ActiveRecord::Migration[7.0]
  def change
    add_column :agents, :connected_with_agent_connect, :boolean, default: false, null: false
  end
end
