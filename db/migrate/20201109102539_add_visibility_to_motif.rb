class AddVisibilityToMotif < ActiveRecord::Migration[6.0]
  def up
    add_column :motifs, :visibility_type, :string, null: false, default: Motif::VISIBLE_AND_NOTIFIED

    Motif.where(disable_notifications_for_users: true).update_all(visibility_type: Motif::VISIBLE_AND_NOT_NOTIFIED)
  end
end
