class SetNotNullOnSuperAdminsNames < ActiveRecord::Migration[7.0]
  def change
    change_column_null :super_admins, :first_name, false
    change_column_null :super_admins, :last_name, false
  end
end
