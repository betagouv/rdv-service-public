class SetIndexOnEmailNotNullForUsers < ActiveRecord::Migration[6.0]
  def change
    remove_index :users, name: "index_users_on_email"
    add_index :users, :email, unique: true, where: "email IS NOT NULL"
  end
end
