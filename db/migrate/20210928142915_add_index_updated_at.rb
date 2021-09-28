# frozen_string_literal: true

class AddIndexUpdatedAt < ActiveRecord::Migration[6.0]
  def change
    add_index :rdvs, :updated_at
  end
end
