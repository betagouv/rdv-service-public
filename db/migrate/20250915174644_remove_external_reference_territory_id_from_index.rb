class RemoveExternalReferenceTerritoryIdFromIndex < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index "external_references", %w[external_id item_type oauth_application_id], unique: true, algorithm: :concurrently
    add_index "external_references", %w[item_id item_type oauth_application_id], unique: true, algorithm: :concurrently

    remove_index "external_references", column: %w[external_id item_type oauth_application_id territory_id]
    remove_index "external_references", column: %w[item_id item_type oauth_application_id territory_id]
  end
end
