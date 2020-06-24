class CreateZones < ActiveRecord::Migration[6.0]
  def change
    create_table :zones do |t|
      t.references :organisation, null: false, foreign_key: true
      t.string :level
      t.string :city_name
      t.string :city_code

      t.timestamps
    end
  end
end
