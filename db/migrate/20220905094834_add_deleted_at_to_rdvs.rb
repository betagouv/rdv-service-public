# frozen_string_literal: true

class AddDeletedAtToRdvs < ActiveRecord::Migration[6.1]
  def change
    add_column :rdvs, :deleted_at, :datetime, null: true
    add_index :rdvs, :deleted_at
  end
end
