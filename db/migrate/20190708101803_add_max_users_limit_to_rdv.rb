class AddMaxUsersLimitToRdv < ActiveRecord::Migration[5.2]
  def change
    add_column :rdvs, :max_users_limit, :integer
  end
end
