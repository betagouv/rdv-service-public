# frozen_string_literal: true

class SetAbsenceOrganisationIdNull < ActiveRecord::Migration[7.0]
  def change
    change_column_null :absences, :organisation_id, true
  end
end
