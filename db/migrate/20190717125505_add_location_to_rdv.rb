class AddLocationToRdv < ActiveRecord::Migration[5.2]
  def change
    add_column :rdvs, :location, :string
    add_column :plage_ouvertures, :location, :string
  end
end
