class AddTextPatternOpsIndexOnUsersEmail < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    add_index :users, :email, opclass: :varchar_pattern_ops, where: "email IS NOT NULL", algorithm: :concurrently, name: "index_users_on_email_with_varchar_pattern_ops"
    remove_index :users, :email, name: "index_users_on_email"
    rename_index :users, "index_users_on_email_with_varchar_pattern_ops", "index_users_on_email"
  end

  def down
    rename_index :users, "index_users_on_email", "index_users_on_email_with_varchar_pattern_ops"
    add_index :users, :email, where: "email IS NOT NULL", algorithm: :concurrently, name: "index_users_on_email"
    remove_index :users, :email, name: "index_users_on_email_with_varchar_pattern_ops"
  end
end
