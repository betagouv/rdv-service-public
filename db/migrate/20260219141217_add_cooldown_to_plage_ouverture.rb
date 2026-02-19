class AddCooldownToPlageOuverture < ActiveRecord::Migration[8.0]
  def change
    add_column :plage_ouvertures, :minutes_between_rdvs, :integer, null: false, default: 0
    add_column :rdvs, :minutes_after_rdv, :integer, null: false, default: 0
  end
end
