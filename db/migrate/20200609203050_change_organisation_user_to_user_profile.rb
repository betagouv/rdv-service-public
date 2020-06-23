class ChangeOrganisationUserToUserProfile < ActiveRecord::Migration[6.0]
  def change
    rename_table :organisations_users, :user_profiles
    add_column :user_profiles, :id, :primary_key
    add_column :user_profiles, :notes, :text
    add_column :user_profiles, :logement, :int

    rename_column :users, :logement, :old_logement
    rename_column :users, :notes, :old_notes

    UserProfile.all.each do |profile|
      profile.update!(logement: profile.user.old_logement, notes: profile.user.old_notes)
    end
  end

end
