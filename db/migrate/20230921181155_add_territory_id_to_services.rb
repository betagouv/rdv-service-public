# frozen_string_literal: true

class AddTerritoryIdToServices < ActiveRecord::Migration[7.0]
  def change
    add_reference :services, :territory, foreign_key: true, index: true
  end
end
