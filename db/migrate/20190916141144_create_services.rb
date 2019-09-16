class CreateServices < ActiveRecord::Migration[6.0]
  def change
    create_table :services do |t|
      t.string :name
      t.references :organisation, foreign_key: true
      t.timestamps
    end
    add_reference :motifs, :service, foreign_key: true
    add_reference :pros, :service, foreign_key: true
  end
end
