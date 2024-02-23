class CreateExports < ActiveRecord::Migration[7.0]
  def change
    create_table :exports, id: :uuid do |t|
      t.datetime :expires_at, null: false
      t.integer :agent_id, null: false
      t.string :file_name, null: false
      t.text :content
      t.jsonb :organisation_ids, null: false
      t.jsonb :options
      t.timestamps
    end

    # Pas de souci de blocage d'écriture vu la durée d'exécution sur une table vide
    safety_assured do
      add_index :exports, :expires_at

      add_index :exports, :agent_id
      add_foreign_key :exports, :agents
    end
  end
end
