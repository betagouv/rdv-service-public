class CreateMotifLibelles < ActiveRecord::Migration[6.0]
  def change
    create_table :motif_libelles do |t|
      t.string :name
      t.references :service, null: false, foreign_key: true

      t.timestamps
    end
  end
end
