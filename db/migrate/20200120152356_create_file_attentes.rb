class CreateFileAttentes < ActiveRecord::Migration[6.0]
  def change
    create_table :file_attentes do |t|
      t.references :rdv, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
