class RemoveRoleFromAgents < ActiveRecord::Migration[6.0]
  def up
    remove_column :agents, :role
  end
end
