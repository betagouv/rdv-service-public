class RenameEvenementType < ActiveRecord::Migration[5.2]
  def change
    remove_column :evenement_types, :motif_id
    drop_table :motifs
    rename_table :evenement_types, :motifs
  end
end
