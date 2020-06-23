class ChangeOrganisationUserToUserProfile < ActiveRecord::Migration[6.0]
  def up
    rename_table :organisations_users, :user_profiles
    add_column :user_profiles, :id, :primary_key
    add_column :user_profiles, :notes, :text
    add_column :user_profiles, :logement, :int

    rename_column :users, :logement, :old_logement
    rename_column :users, :notes, :old_notes

    UserProfile.each do |profile|
      profile.update(logement: user.old_logement, notes: user.old_notes)
    end
  end

  def down
    UserProfile.each do |profile|
      profile.user.update(old_logement: profile.logement, old_notes: profile.notes)
    end

    rename_column :users, :old_logement, :logement
    rename_column :users, :old_notes, :notes

    remove_column :user_profiles, :id, :primary_key
    remove_column :user_profiles, :notes, :text
    remove_column :user_profiles, :logement, :int
    rename_table :organisations_users, :user_profiles
  end
end
