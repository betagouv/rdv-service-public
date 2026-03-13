class AddPublicStatsToTerritories < ActiveRecord::Migration[8.0]
  def change
    add_column :territories, :public_stats, :boolean, default: false, null: false
  end
end
