# frozen_string_literal: true

class AddPlageOuvertureAbsenceIndexUpdatedAt < ActiveRecord::Migration[6.1]
  def change
    add_index :absences, :updated_at
    add_index :plage_ouvertures, :updated_at
  end
end
