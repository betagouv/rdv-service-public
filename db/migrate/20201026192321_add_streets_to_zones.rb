class AddStreetsToZones < ActiveRecord::Migration[6.0]
  def change
    add_column :zones, :street_name, :string
    add_column :zones, :street_ban_id, :string
  end
end
