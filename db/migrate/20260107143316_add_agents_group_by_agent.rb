class AddAgentsGroupByAgent < ActiveRecord::Migration[8.0]
  def change
    add_column :agents, :group_by_agent, :boolean, null: false, default: false
  end
end
