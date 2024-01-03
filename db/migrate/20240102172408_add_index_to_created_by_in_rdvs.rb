class AddIndexToCreatedByInRdvs < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :rdvs, %i[created_by_type created_by_id], algorithm: :concurrently
  end
end
