# frozen_string_literal: true

class RemoveUniqueIndexFromAgentsEmail < ActiveRecord::Migration[7.0]
  def up
    change_column_null :agents, :email, :string, null: true
    change_column_null :agents, :uid, :string, null: true
  end

  def down
    change_column_null :agents, :email, :string, null: false
    change_column_null :agents, :uid, :string, null: false
  end
end
