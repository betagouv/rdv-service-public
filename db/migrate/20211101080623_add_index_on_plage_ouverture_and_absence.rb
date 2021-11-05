# frozen_string_literal: true

class AddIndexOnPlageOuvertureAndAbsence < ActiveRecord::Migration[6.0]
  def change
    add_index :plage_ouvertures, :first_day
    add_index :plage_ouvertures, "tsrange(first_day, recurrence_ends_at, '[)')", using: :gist
    add_index :plage_ouvertures, :recurrence, where: "recurrence IS NOT NULL"
    add_index :absences, :first_day
    add_index :absences, "tsrange(first_day, recurrence_ends_at, '[)')", using: :gist
    add_index :absences, :recurrence, where: "recurrence IS NOT NULL"
  end
end
