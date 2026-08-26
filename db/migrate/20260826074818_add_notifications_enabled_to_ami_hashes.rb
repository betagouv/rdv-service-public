class AddNotificationsEnabledToAmiHashes < ActiveRecord::Migration[8.0]
  def change
    # La table n'est pas encore utilisée, donc on peut la dropper et la recréer sous un autre nom
    drop_table :ami_france_connect_hashes do |t|
      t.string :fc_hash, null: false
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.timestamps
    end

    create_table :user_ami_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :fc_hash, null: false
      t.boolean :notify_by_ami, default: false, null: false
      t.timestamps
    end
  end
end
