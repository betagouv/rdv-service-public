# frozen_string_literal: true

class AddEnableContextFieldToTerritory < ActiveRecord::Migration[6.1]
  def change
    add_column :territories, :enable_context_field, :boolean, default: false

    Territory.all.update_all(enable_context_field: true)
  end
end
