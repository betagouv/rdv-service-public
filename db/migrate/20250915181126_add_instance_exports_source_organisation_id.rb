class AddInstanceExportsSourceOrganisationId < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_column :instance_exports, :source_organisation_id, :integer

    add_index :instance_exports, :source_organisation_id, algorithm: :concurrently
  end
end
