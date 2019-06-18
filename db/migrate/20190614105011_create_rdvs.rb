class CreateRdvs < ActiveRecord::Migration[5.2]
  def change
    create_table :rdvs do |t|
      t.string :name
      t.integer :duration_in_min, default: 30, null: false
      t.datetime :start_at, null: false
      t.references :organisation, foreign_key: true

      t.timestamps
    end
  end
end
