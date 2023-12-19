class AddRoleToSuperAdmin < ActiveRecord::Migration[7.0]
  def change
    create_enum :role, %w[legacy_admin support]
    add_column :super_admins, :role, :role, default: "support", null: false
  end
end
