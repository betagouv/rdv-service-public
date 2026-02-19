class AddCooldownToPlageOuverture < ActiveRecord::Migration[8.0]
  def change
    add_column :plage_ouvertures, :cooldown, :integer, null: false, default: 0
  end
end
