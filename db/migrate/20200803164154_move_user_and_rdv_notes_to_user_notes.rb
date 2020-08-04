class MoveUserAndRdvNotesToUserNotes < ActiveRecord::Migration[6.0]
  def up
    create_table :user_notes do |t|
      t.belongs_to :user, null: false, foreign_key: true
      t.belongs_to :organisation, null: false, foreign_key: true
      t.belongs_to :agent, null: true
      t.text :text
      t.timestamps
    end

    rename_column :rdvs, :notes, :old_notes

    UserProfile.where.not(notes: ["", nil]).each do |profile|
      note = "*attention cette note note est plus ancienne que la date affichée*   " + profile.notes
      UserNote.create(user: profile.user, organisation: profile.organisation, agent: nil, text: note)
    end

    Rdv.where.not(old_notes: ["", nil]).each do |rdv|
      rdv.users.where(responsible_id: ["", nil]).each do |user|
        note = "*attention cette note note est plus ancienne que la date affichée*   " + rdv.old_notes
        UserNote.create(user: user, organisation: rdv.organisation, agent: rdv.agents.first, text: note)
      end
    end
  end

  def down
    drop_table :user_notes
    rename_column :rdvs, :old_notes, :notes
  end
end
