class AddProconnect2faActiveToAgents < ActiveRecord::Migration[8.0]
  def change
    add_column :agents, :pro_connect_2fa_active, :boolean
  end
end
