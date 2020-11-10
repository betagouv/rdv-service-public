class AddVisibilityToMotif < ActiveRecord::Migration[6.0]
  def up
    add_column :motifs, :visibility_type, :integer, null: false, default: Motif.visibility_types[:visible_and_notified]

    Motif.where(disable_notifications_for_users: true).update_all(visibility_type: Motif.visibility_types[:visible_and_not_notified])
  end
end
