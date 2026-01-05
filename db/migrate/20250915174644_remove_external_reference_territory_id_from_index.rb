class RemoveExternalReferenceTerritoryIdFromIndex < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    duplicates_on_first_index = ExternalReference.joins <<~SQL.squish
      INNER JOIN external_references AS ext_refs2 ON
        external_references.id != ext_refs2.id
        AND external_references.external_id = ext_refs2.external_id
        AND external_references.item_type = ext_refs2.item_type
        AND external_references.oauth_application_id = ext_refs2.oauth_application_id
    SQL

    duplicate_ids = duplicates_on_first_index.limit(10).pluck(:id)
    raise "Duplicate external reference #{duplicate_ids}" if duplicate_ids.any?

    duplicates_on_second_index = ExternalReference.joins <<~SQL.squish
      INNER JOIN external_references AS ext_refs2 ON
        external_references.id != ext_refs2.id
        AND external_references.external_id = ext_refs2.external_id
        AND external_references.item_type = ext_refs2.item_type
        AND external_references.oauth_application_id = ext_refs2.oauth_application_id
    SQL

    duplicate_ids = duplicates_on_second_index.limit(10).pluck(:id)
    raise "Duplicate external reference #{duplicate_ids}" if duplicate_ids.any?

    add_index "external_references", %w[external_id item_type oauth_application_id], unique: true, algorithm: :concurrently
    add_index "external_references", %w[item_id item_type oauth_application_id], unique: true, algorithm: :concurrently

    remove_index "external_references", column: %w[external_id item_type oauth_application_id territory_id]
    remove_index "external_references", column: %w[item_id item_type oauth_application_id territory_id]
  end
end
ActiveRecord::Base.logger = Logger.new(STDOUT)
