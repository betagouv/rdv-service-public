class RemoveOldNotesFromUserProfiles < ActiveRecord::Migration[6.0]
  def change
    remove_column :user_profiles, :old_notes
  end
end
