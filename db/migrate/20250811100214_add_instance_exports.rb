class AddInstanceExports < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    create_table :instance_exports do |t|
      t.references :agent, foreign_key: true, index: false, null: false
      t.integer :destination_organisation_id
      t.text :api_token, null: false
      t.text :refresh_token, null: false
      t.references :good_job_batch, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :instance_exports, :agent_id, algorithm: :concurrently
  end
end
