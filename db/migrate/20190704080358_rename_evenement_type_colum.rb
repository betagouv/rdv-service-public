class RenameEvenementTypeColum < ActiveRecord::Migration[5.2]
  def change
    rename_column :rdvs, :evenement_type_id, :motif_id
  end
end
