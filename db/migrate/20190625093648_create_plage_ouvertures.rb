class CreatePlageOuvertures < ActiveRecord::Migration[5.2]
  def change
    create_table :plage_ouvertures do |t|
      t.references :pro, foreign_key: true
      t.string :title
      t.references :organisation, foreign_key: true
      t.date :first_day, null: false
      t.time :start_time, null: false
      t.time :end_time, null: false

      t.timestamps
    end

    create_table :motifs_plage_ouvertures, id: false do |t|
      t.belongs_to :motif, index: true
      t.belongs_to :plage_ouverture, index: true
    end
  end
end
