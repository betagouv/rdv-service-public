# frozen_string_literal: true

class AddRdvsUsersNotificationsFlags < ActiveRecord::Migration[6.0]
  def change
    add_column :rdvs_users, :send_lifecycle_notifications, :boolean
    add_column :rdvs_users, :send_reminder_notification, :boolean

    up_only do
      notified_motifs = Motif.where(visibility_type: "visible_and_notified")
      RdvsUser.joins(:rdv)
        .where(rdvs: { motif_id: notified_motifs })
        .update_all(send_lifecycle_notifications: true, send_reminder_notification: true)
      RdvsUser.joins(:rdv)
        .where.not(rdvs: { motif_id: notified_motifs })
        .update_all(send_lifecycle_notifications: false, send_reminder_notification: false)
    end

    change_column_null :rdvs_users, :send_lifecycle_notifications, false
    change_column_null :rdvs_users, :send_reminder_notification, false
  end
end
