class AddRoleToPros < ActiveRecord::Migration[5.2]
  def change
    add_column :pros, :role, :integer, default: 0
  end
end
