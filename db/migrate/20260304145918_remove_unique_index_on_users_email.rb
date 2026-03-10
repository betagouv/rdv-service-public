class RemoveUniqueIndexOnUsersEmail < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    remove_index :users, name: "index_users_on_email"
    add_index :users, :email, where: "(email IS NOT NULL)", algorithm: :concurrently
  end

  def down
    remove_index :users, name: "index_users_on_email"
    add_index :users, :email, unique: true, where: "(email IS NOT NULL)", algorithm: :concurrently
  end
end
