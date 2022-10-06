# frozen_string_literal: true

class RemoveApiOptionsFromTerritories < ActiveRecord::Migration[6.1]
  def change
    remove_column :territories, :api_options, :string
  end
end
