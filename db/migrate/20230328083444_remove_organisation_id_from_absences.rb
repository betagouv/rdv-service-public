# frozen_string_literal: true

class RemoveOrganisationIdFromAbsences < ActiveRecord::Migration[7.0]
  def change
    remove_column :absences, :organisation_id, :boolean
  end
end
