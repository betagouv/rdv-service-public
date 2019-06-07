class CreateMotifs < ActiveRecord::Migration[5.2]
  def change
    create_table :motifs do |t|
      t.references :specialite, foreign_key: true
      t.references :organisation, foreign_key: true
      t.string :name
      t.timestamps
    end
  end
end
