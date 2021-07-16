# frozen_string_literal: true

class UpdateAbsenceTitleToMandatory < ActiveRecord::Migration[6.0]
  def change
    Absence.where(title: ["", nil]).update(title: "Absence")

    change_column_null :absences, :title, false
  end
end
