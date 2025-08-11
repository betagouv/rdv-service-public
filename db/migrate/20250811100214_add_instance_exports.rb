class AddInstanceExports < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    create_table :instance_exports do |t|
      t.references :agent, foreign_key: true, index: false, null: false
      t.integer :destination_organisation_id, null: false
      t.text :api_token, null: false
      t.text :refresh, null: false

      t.timestamps
    end

    add_index :instance_exports, :agent_id, algorithm: :concurrently
  end
end
