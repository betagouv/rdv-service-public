# frozen_string_literal: true

class AddTerritoryApiOptions < ActiveRecord::Migration[6.0]
  def change
    add_column :territories, :api_options, :string, array: true, null: false, default: []
  end
end
