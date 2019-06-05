class CreateSpecialites < ActiveRecord::Migration[5.2]
  def change
    create_table :specialites do |t|
      t.string :name
      t.references :organisation, foreign_key: true

      t.timestamps
    end

    add_column :pros, :specialite_id, :bigint
    add_index :pros, :specialite_id
  end
end
