class MigrateUserNotesBackToUserProfiles < ActiveRecord::Migration[6.0]
  def up
    add_column :user_profiles, :notes, :text
    pairs = UserNote.select(:user_id, :organisation_id).distinct
    users_by_id = User.where(id: pairs.pluck(:user_id)).to_a.index_by(&:id)
    # > 2000 users with notes in prod
    pairs.each { migrate_user_notes(users_by_id[_1.user_id], _1.organisation_id) }
  end

  def down
    remove_column :user_profiles, :notes
  end

  private

  def migrate_user_notes(user, organisation_id)
    orga_user_notes = user.notes_for(organisation_id)
    user_profile = user.profile_for(organisation_id)
    if user_profile.nil?
      print "---"
      print("no user profile found for user #{user.full_name} and orga #{Organisation.find(organisation_id).name}. Notes: #{orga_user_notes.map(&:text).join(' - ')}")
      print "---"
      # counted 6 cases in prod, notes don't seem incredibly important,
      # I think it's ok to ignore
      return
    end
    user_profile.update_columns(notes: orga_user_notes.map(&:text).join("\n"))
  end
end
