# frozen_string_literal: true

class AddVisibileUsersThroughoutTheTerritoryToTerritory < ActiveRecord::Migration[7.0]
  def change
    add_column :territories, :visible_users_throughout_the_territory, :boolean, default: false, nil: false
  end
end
