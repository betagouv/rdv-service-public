# frozen_string_literal: true

class RemoveUniqueIndexFromAgentsEmail < ActiveRecord::Migration[7.0]
  def up
    change_column_null :agents, :email, true
    change_column_null :agents, :uid, true

    remove_index :agents, :email
    add_index :agents, :email, unique: true, where: "email IS NOT NULL"

    remove_index :agents, %i[uid provider]
    add_index :agents, %i[uid provider], unique: true, where: "uid IS NOT NULL"
  end

  def down
    change_column_null :agents, :email, false
    change_column_null :agents, :uid, false

    remove_index :agents, :email
    add_index :agents, :email, unique: true

    remove_index :agents, %i[uid provider]
    add_index :agents, %i[uid provider], unique: true
  end
end
