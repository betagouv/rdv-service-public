class CreateExternalReferences < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    create_table :external_references do |t|
      t.string :item_type, null: false
      t.bigint :item_id, null: false
      t.references :oauth_application, null: false, index: false, foreign_key: true
      t.bigint :external_id, null: false
      t.text :external_url

      t.timestamps
    end

    add_index :external_references, %i[item_id item_type oauth_application_id], algorithm: :concurrently, unique: true
  end
end
