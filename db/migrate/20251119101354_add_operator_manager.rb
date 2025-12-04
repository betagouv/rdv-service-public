class AddOperatorManager < ActiveRecord::Migration[8.0]
  def change
    create_table :operator_managers do |t|
      t.text :first_name
      t.text :last_name
      t.text :email
      t.text :pro_connect_openid_sub
      t.references :operator, null: false, foreign_key: true

      t.index :email, unique: true

      t.timestamps
    end
  end
end
