class AddSiretIndex < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :agents, :proconnect_siret, algorithm: :concurrently
  end
end
