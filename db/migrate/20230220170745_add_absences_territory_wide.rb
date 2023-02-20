# frozen_string_literal: true

class AddAbsencesTerritoryWide < ActiveRecord::Migration[7.0]
  def change
    add_column :absences, :territory_wide, :boolean, default: false, null: false
    add_index :absences, :territory_wide, where: "territory_wide IS TRUE"
  end
end
