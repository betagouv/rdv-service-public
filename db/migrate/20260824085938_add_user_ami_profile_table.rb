class AddUserAmiProfileTable < ActiveRecord::Migration[8.0]
  def change
    create_table :ami_france_connect_hashes do |t|
      t.string :fc_hash, null: false
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.timestamps
    end
  end
end
