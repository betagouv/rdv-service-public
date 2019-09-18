class AddDepartementToOrganisation < ActiveRecord::Migration[5.2]
  def change
    add_column :organisations, :departement, :string
  end
end
