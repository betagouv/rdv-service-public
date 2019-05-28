class AddFullNameToPros < ActiveRecord::Migration[5.2]
  def change
    add_column :pros, :first_name, :string
    add_column :pros, :last_name, :string
  end
end
