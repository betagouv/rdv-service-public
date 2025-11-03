class AddTokenOnPrescripteur < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_column :prescripteurs, :token, :string

    add_index :prescripteurs, :token, algorithm: :concurrently, where: "token IS NOT NULL"
  end
end
