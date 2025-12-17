class AddPreferencesToAgents < ActiveRecord::Migration[8.0]
  def change
    add_column :agents, :preferences, :jsonb, null: false, default: {}
  end
end
