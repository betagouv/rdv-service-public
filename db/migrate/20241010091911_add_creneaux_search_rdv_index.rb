class AddCreneauxSearchRdvIndex < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :rdvs, %i[status starts_at ends_at], algorithm: :concurrently
  end
end
