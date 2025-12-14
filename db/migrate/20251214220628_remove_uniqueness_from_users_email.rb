class RemoveUniquenessFromUsersEmail < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    remove_index :users, :email, name: "index_users_on_email"
    add_index :users, :email, unique: false, where: "(email IS NOT NULL)", name: "index_users_on_email", algorithm: :concurrently
  end

  def down
    remove_index :users, :email, name: "index_users_on_email"
    add_index :users, :email, unique: true, where: "(email IS NOT NULL)", name: "index_users_on_email", algorithm: :concurrently
  end
end
