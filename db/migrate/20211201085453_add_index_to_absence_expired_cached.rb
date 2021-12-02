# frozen_string_literal: true

class AddIndexToAbsenceExpiredCached < ActiveRecord::Migration[6.0]
  def change
    add_index :absences, :expired_cached
  end
end
