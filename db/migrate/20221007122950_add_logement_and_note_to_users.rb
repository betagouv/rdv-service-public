# frozen_string_literal: true

class AddLogementAndNoteToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :logement, :integer
    add_column :users, :notes, :text

    up_only do
      profile_with_notes = UserProfile.where.not(notes: ["", nil])
      profile_with_logement = UserProfile.where.not(logement: ["", nil])

      UserProfile.where(id: profile_with_notes + profile_with_logement).distinct.find_each do |profile|
        user = profile.user
        # On part du principe que le logement est identique pour toutes et tous normalement
        # Il y a 34 usagers qui ont 2 profiles avec des valeurs différentes sur le logement
        #
        # ```
        # irb(main):021:0> User.joins(:user_profiles)
        #   .group(:id)
        #   .having("count(user_profiles.id) > 1")
        #   .select {|u| u.user_profiles.pluck(:logement).uniq.compact.count > 1}
        #   .count
        # => 34
        # ```
        #
        # Ces profiles sont sur 3 départements
        #
        # ```
        # irb(main):023:0> User.joins(:user_profiles)
        #   .group(:id)
        #   .having("count(user_profiles.id) > 1")
        #   .select {|u| u.user_profiles.pluck(:logement).uniq.compact.count > 1}
        #   .flat_map(&:organisations)
        #   .uniq
        #   .flat_map(&:territory)
        #   .flat_map(&:name)
        #   .uniq
        # => ["Pas-de-Calais", "Pyrénées-Atlantiques", "Seine-et-Marne"]
        # ```
        # Le Pas-de-Calais et les Pyrénées-Atlantique n'ont pas activé l'utilisation du logement.
        #

        new_notes = [user.notes, profile.notes].compact.join("; ")
        user.update(logement: profile.logement, notes: new_notes)
      end
    end

    rename_column :user_profiles, :logement, :old_logement
    rename_column :user_profiles, :notes, :old_notes
  end
end
