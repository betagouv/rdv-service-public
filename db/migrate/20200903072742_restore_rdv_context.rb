# prod run: :user_note_destroyed=>3509, :context_cleaned=>42

class RestoreRdvContext < ActiveRecord::Migration[6.0]
  def up
    rename_column :rdvs, :old_notes, :context
    Rails.logger.debug "will verify #{rdvs_to_migrate.count} rdvs with a context"
    counters = { user_note_destroyed: 0, context_cleaned: 0 }

    # disable AR logging, it's quite intense
    old_logger = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = nil

    rdvs_to_migrate.each do |rdv|
      res = migrate_rdv(rdv)
      counters[res] += 1
    end

    ActiveRecord::Base.logger = old_logger
    Rails.logger.debug "finished ! totals: #{counters}"
  end

  def down
    rename_column :rdvs, :context, :old_notes
  end

  private

  def rdvs_to_migrate
    @rdvs_to_migrate = Rdv.includes(:organisation).where.not(context: [nil, ""])
  end

  def migrate_rdv(rdv)
    user_note = find_rdv_matching_user_note(rdv)
    if user_note.present?
      Rails.logger.debug "destroying user_note!"
      user_note.destroy!
      :user_note_destroyed
    else
      Rails.logger.debug "user_note disappeared, cleaning context..."
      rdv.update_columns(context: nil)
      :context_cleaned
    end
  end

  def find_rdv_matching_user_note(rdv)
    target_user = rdv.users.responsible.first || rdv.users.first
    return nil if target_user.blank?

    UserNote.find_by(
      user: target_user,
      organisation: rdv.organisation,
      agent: nil,
      text: rdv.context
    )
  end
end
