class RemoveIndexServicesShortName < ActiveRecord::Migration[7.1]
  def change
    remove_index :services, "lower(short_name)", unique: true, name: "index_services_on_lower_short_name"
  end
end
