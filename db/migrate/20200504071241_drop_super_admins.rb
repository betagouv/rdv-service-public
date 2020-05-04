class DropSuperAdmins < ActiveRecord::Migration[6.0]
  def up
    drop_table :super_admins
  end
end
