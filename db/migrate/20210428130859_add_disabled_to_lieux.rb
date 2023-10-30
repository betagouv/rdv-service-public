class AddDisabledToLieux < ActiveRecord::Migration[6.0]
  def change
    add_column :lieux, :enabled, :boolean, null: false, default: true
    add_index :lieux, :enabled
  end
end
