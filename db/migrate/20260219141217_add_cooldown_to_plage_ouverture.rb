class AddCooldownToPlageOuverture < ActiveRecord::Migration[8.0]
  def change
    add_column :plage_ouvertures, :minutes_after_rdvs, :integer, default: 0, null: false
    add_column :rdvs, :minutes_after_rdv, :integer, default: 0, null: false
  end
end
