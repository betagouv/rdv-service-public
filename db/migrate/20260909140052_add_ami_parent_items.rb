class AddAmiParentItems < ActiveRecord::Migration[8.0]
  def change
    create_table :external_ami_items do |t|
      t.string :item_type, null: false
      t.string :item_id, null: false
      t.string :partner_id, null: false
      t.references :rdv_plan, null: false, foreign_key: true, index: { unique: true }
      t.timestamps
    end
  end
end
