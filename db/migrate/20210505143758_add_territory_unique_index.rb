# frozen_string_literal: true

class AddTerritoryUniqueIndex < ActiveRecord::Migration[6.0]
  def change
    change_column_default :territories, :departement_number, from: nil, to: ""
    change_column_null :territories, :departement_number, false, ""
    add_index :territories, :departement_number, unique: true, where: "departement_number <> ''"
  end
end
