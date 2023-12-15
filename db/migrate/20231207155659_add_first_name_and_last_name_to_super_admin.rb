class AddFirstNameAndLastNameToSuperAdmin < ActiveRecord::Migration[7.0]
  def change
    add_column :super_admins, :first_name, :string
    add_column :super_admins, :last_name, :string
  end
end
