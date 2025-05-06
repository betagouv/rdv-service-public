class CreateTerritoryCreationRequestsTable < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    create_enum :creation_status, %w[accepted refused]
    create_table :territory_creation_requests do |t|
      t.references :agent, foreign_key: true, index: false, null: false
      t.string :territory_name
      t.string :organisation_name
      t.string :service_name
      t.enum :response, enum_type: :creation_status

      t.timestamps
    end

    add_index :territory_creation_requests, :agent_id, algorithm: :concurrently, unique: true
  end
end
