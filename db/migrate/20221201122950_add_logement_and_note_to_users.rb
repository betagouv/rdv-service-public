# frozen_string_literal: true

class AddLogementAndNoteToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :logement, :integer
    add_column :users, :notes, :text

    profile_with_notes = UserProfile.where.not(notes: ["", nil])
    profile_with_logement = UserProfile.where.not(logement: ["", nil])

    UserProfile.where(id: profile_with_notes + profile_with_logement).distinct.find_each do |profile|
      user = profile.user
      new_notes = [user.notes, profile.notes].compact.join("; ")
      user.update(logement: profile.logement, notes: new_notes)
    end

    rename_column :user_profiles, :logement, :old_logement
    rename_column :user_profiles, :notes, :old_notes
  end
end
