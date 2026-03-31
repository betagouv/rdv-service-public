class AddAddressWithoutGeocodingToLieux < ActiveRecord::Migration[8.0]
  def change
    add_column :lieux, :address_without_geocoding, :boolean, default: false, null: false
  end
end
