class AddOperator < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    create_table :operators do |t|
      t.string :name
      t.timestamps
    end

    add_reference :territories, :operator, index: { algorithm: :concurrently }
  end
end
