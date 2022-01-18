# frozen_string_literal: true

class UpdateTsRangeIndexes < ActiveRecord::Migration[6.1]
  def up
    remove_index :absences, "tsrange(first_day, recurrence_ends_at, '[)')", using: :gist
    remove_index :plage_ouvertures, "tsrange(first_day, recurrence_ends_at, '[)')", using: :gist

    add_index :absences, "tsrange(first_day, recurrence_ends_at, '[]')", using: :gist
    add_index :plage_ouvertures, "tsrange(first_day, recurrence_ends_at, '[]')", using: :gist
  end
end
