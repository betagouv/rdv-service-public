class AddIndexOnAntsPreDemandeNumber < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :users, :ants_pre_demande_number, algorithm: :concurrently, where: "ants_pre_demande_number IS NOT NULL"
  end
end
