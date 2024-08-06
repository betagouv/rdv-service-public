class AddVersionsIdentifiedIndex < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def change
    add_index :versions, :identified, algorithm: :concurrently
  end
end
