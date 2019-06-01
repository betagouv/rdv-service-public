class AddAddressToSite < ActiveRecord::Migration[5.2]
  def change
    add_column :sites, :address, :string
  end
end
