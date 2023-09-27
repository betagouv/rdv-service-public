# frozen_string_literal: true

class RemoveOldFieldsFromUserProfiles < ActiveRecord::Migration[7.0]
  def change
    remove_column :user_profiles, :old_logement, :string
    remove_column :user_profiles, :old_notes, :string
  end
end
