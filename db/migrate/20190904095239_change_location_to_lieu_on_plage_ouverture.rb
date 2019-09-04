class ChangeLocationToLieuOnPlageOuverture < ActiveRecord::Migration[5.2]
  def change
    remove_column :plage_ouvertures, :location
    add_reference :plage_ouvertures, :lieu, foreign_key: true
  end
end
