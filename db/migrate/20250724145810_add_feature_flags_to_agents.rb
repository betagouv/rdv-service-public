class AddFeatureFlagsToAgents < ActiveRecord::Migration[7.1]
  def change
    add_column :agents, :feature_flags, :jsonb, default: {}
  end
end
