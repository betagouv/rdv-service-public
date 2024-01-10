class AddIndexToCreatedBy < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :participations, %i[created_by_type created_by_id], algorithm: :concurrently
    add_index :rdvs, %i[created_by_type created_by_id], algorithm: :concurrently
  end
end
