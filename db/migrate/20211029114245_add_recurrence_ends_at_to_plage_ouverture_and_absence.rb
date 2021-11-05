# frozen_string_literal: true

class AddRecurrenceEndsAtToPlageOuvertureAndAbsence < ActiveRecord::Migration[6.0]
  def change
    add_column :plage_ouvertures, :recurrence_ends_at, :datetime
    add_column :absences, :recurrence_ends_at, :datetime

    Absence.not_expired.where.not(recurrence: ["", nil]).each do |absence|
      if absence.recurrence.ends_at
        absence.update(recurrence_ends_at: absence.recurrence.ends_at)
      end
    end

    PlageOuverture.not_expired.where.not(recurrence: ["", nil]).each do |po|
      if po.recurrence.ends_at
        po.update(recurrence_ends_at: po.recurrence.ends_at)
      end
    end
  end
end
