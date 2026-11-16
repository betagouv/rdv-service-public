class CreateDeletedRdvs < ActiveRecord::Migration[8.1]
  # Pas de foreign keys volontairement : on veut conserver ces données même si les
  # organisations, motifs, lieux, usagers ou agents référencés sont supprimés par la suite.
  def change
    create_table :deleted_rdvs do |t|
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.bigint :organisation_id, null: false
      t.bigint :motif_id
      t.string :motif_name
      t.bigint :lieu_id
      t.string :status
      t.string :created_by_type
      t.bigint :created_by_id
      t.string :created_by_name # copie du nom, au cas où created_by_id pointe vers un agent supprimé
      t.bigint :user_ids, array: true, default: [], null: false
      t.bigint :agent_ids, array: true, default: [], null: false

      t.timestamps # created_at correspond à la date de suppression du RDV
    end

    add_index :deleted_rdvs, %i[organisation_id created_at]
    add_index :deleted_rdvs, :agent_ids, using: :gin
  end
end
