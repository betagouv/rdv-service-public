class CreateAbsences < ActiveRecord::Migration[5.2]
  def change
    create_table :absences do |t|
      t.references :pro, foreign_key: true
      t.string :title
      t.references :organisation, foreign_key: true
      t.datetime :starts_at
      t.datetime :ends_at

      t.timestamps
    end
  end
end
