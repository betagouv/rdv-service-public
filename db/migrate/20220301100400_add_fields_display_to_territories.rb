# frozen_string_literal: true

class AddFieldsDisplayToTerritories < ActiveRecord::Migration[6.1]
  def change
    add_column :territories, :enable_notes_field, :boolean, default: false
    add_column :territories, :enable_caisse_affiliation_field, :boolean, default: false
    add_column :territories, :enable_affiliation_number_field, :boolean, default: false
    add_column :territories, :enable_family_situation_field, :boolean, default: false
    add_column :territories, :enable_number_of_children_field, :boolean, default: false
    add_column :territories, :enable_logement_field, :boolean, default: false

    up_only do
      Territory.update_all(
        enable_notes_field: true,
        enable_caisse_affiliation_field: true,
        enable_affiliation_number_field: true,
        enable_family_situation_field: true,
        enable_number_of_children_field: true,
        enable_logement_field: true
      )
    end
  end
end
