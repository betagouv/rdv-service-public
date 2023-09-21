# frozen_string_literal: true

class AddTerritoryIdToServices < ActiveRecord::Migration[7.0]
  def change
    add_column :services, :territory_id, :integer
  end
end
