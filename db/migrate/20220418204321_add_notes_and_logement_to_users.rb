class AddNotesAndLogementToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :notes, :text
    add_column :users, :logement, :integer

    User.find_each do |user|
      user.user_profiles.each do |profile|
        user.notes = (user.notes || "") + profile.notes if profile.notes.present?
        user.logement = profile.logement if profile.logement.present?
        user.save!
      end
    end
  end
end
