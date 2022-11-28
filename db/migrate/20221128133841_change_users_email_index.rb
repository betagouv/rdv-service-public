class ChangeUsersEmailIndex < ActiveRecord::Migration[7.0]
  def change
    remove_index "users", "email", name: "index_users_on_email", unique: true, where: "(email IS NOT NULL)"
    add_index "users", "email", name: "index_users_on_email", unique: true, where: "(email IS NOT NULL AND encrypted_password != '')"
  end
end
