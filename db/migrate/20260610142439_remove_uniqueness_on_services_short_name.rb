class RemoveUniquenessOnServicesShortName < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    remove_index :services, name: "index_services_on_lower_short_name"
    add_index :services, "lower(short_name)", name: "index_services_on_lower_short_name", algorithm: :concurrently
  end

  def down
    remove_index :services, name: "index_services_on_lower_short_name"
    add_index :services, "lower(short_name)", unique: true, name: "index_services_on_lower_short_name", algorithm: :concurrently
  end
end
