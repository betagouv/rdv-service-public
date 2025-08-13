class CreateJusticeLieuxMatches < ActiveRecord::Migration[7.2]
  def change
    create_table :justice_lieux_matches do |t|
      t.string :ee_id, null: false
      t.bigint :lieu_id, null: false
      t.timestamps
    end
  end
end
