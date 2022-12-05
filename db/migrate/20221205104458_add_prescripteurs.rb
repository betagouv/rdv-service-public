# frozen_string_literal: true

class AddPrescripteurs < ActiveRecord::Migration[7.0]
  def change
    add_enum_value :user_created_through, "prescripteur"

    create_table :prescripteurs do |t|
      t.bigint :rdvs_user_id, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.string :phone_number
      t.string :phone_number_formatted
      t.timestamps null: false
    end

    add_index :prescripteurs, :rdvs_user_id, unique: true
    add_foreign_key :prescripteurs, :rdvs_users
  end
end
