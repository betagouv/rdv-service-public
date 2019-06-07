class CreateEvenementTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :evenement_types do |t|
      t.string :name
      t.references :motif, foreign_key: true
      t.string :color

      t.timestamps
    end
  end
end
