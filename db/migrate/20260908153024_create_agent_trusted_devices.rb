class CreateAgentTrustedDevices < ActiveRecord::Migration[8.0]
  def change
    create_table :agent_trusted_devices do |t|
      t.references :agent, null: false, foreign_key: true
      t.string :token_digest, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end
    add_index :agent_trusted_devices, :token_digest, unique: true
    add_index :agent_trusted_devices, :expires_at
  end
end
