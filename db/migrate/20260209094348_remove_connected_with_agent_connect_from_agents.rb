class RemoveConnectedWithAgentConnectFromAgents < ActiveRecord::Migration[8.0]
  def change
    safety_assured { remove_column :agents, :connected_with_agent_connect, :boolean, default: false, null: false }
  end
end
