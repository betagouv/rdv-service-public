class ReuniteProdSchema < ActiveRecord::Migration[7.0]
  def up
    enable_extension "pg_stat_statements"

    change_column :absences, :created_at, :datetime, precision: 6
    change_column :absences, :updated_at, :datetime, precision: 6
    change_column :absences, :recurrence_ends_at, :datetime, precision: 6
    change_column :agents, :reset_password_sent_at, :datetime, precision: 6
    change_column :agents, :remember_created_at, :datetime, precision: 6
    change_column :agents, :created_at, :datetime, precision: 6
    change_column :agents, :updated_at, :datetime, precision: 6
    change_column :agents, :confirmed_at, :datetime, precision: 6
    change_column :agents, :confirmation_sent_at, :datetime, precision: 6
    change_column :agents, :invitation_created_at, :datetime, precision: 6
    change_column :agents, :invitation_sent_at, :datetime, precision: 6
    change_column :agents, :invitation_accepted_at, :datetime, precision: 6
    change_column :agents, :deleted_at, :datetime, precision: 6
    change_column :agents, :current_sign_in_at, :datetime, precision: 6
    change_column :agents, :last_sign_in_at, :datetime, precision: 6
    change_column :file_attentes, :last_creneau_sent_at, :datetime, precision: 6
    change_column :lieux, :created_at, :datetime, precision: 6
    change_column :lieux, :updated_at, :datetime, precision: 6
    change_column :motifs, :created_at, :datetime, precision: 6
    change_column :motifs, :updated_at, :datetime, precision: 6
    change_column :motifs, :deleted_at, :datetime, precision: 6
    change_column :organisations, :created_at, :datetime, precision: 6
    change_column :organisations, :updated_at, :datetime, precision: 6
    change_column :plage_ouvertures, :created_at, :datetime, precision: 6
    change_column :plage_ouvertures, :updated_at, :datetime, precision: 6
    change_column :plage_ouvertures, :recurrence_ends_at, :datetime, precision: 6
    change_column :rdvs, :starts_at, :datetime, precision: 6
    change_column :rdvs, :created_at, :datetime, precision: 6
    change_column :rdvs, :updated_at, :datetime, precision: 6
    change_column :rdvs, :cancelled_at, :datetime, precision: 6
    change_column :rdvs, :ends_at, :datetime, precision: 6
    change_column :rdvs_users, :invitation_created_at, :datetime, precision: 6
    change_column :rdvs_users, :invitation_sent_at, :datetime, precision: 6
    change_column :rdvs_users, :invitation_accepted_at, :datetime, precision: 6
    change_column :super_admins, :created_at, :datetime, precision: 6
    change_column :super_admins, :updated_at, :datetime, precision: 6
    change_column :users, :created_at, :datetime, precision: 6
    change_column :users, :updated_at, :datetime, precision: 6
    change_column :users, :reset_password_sent_at, :datetime, precision: 6
    change_column :users, :remember_created_at, :datetime, precision: 6
    change_column :users, :confirmed_at, :datetime, precision: 6
    change_column :users, :confirmation_sent_at, :datetime, precision: 6
    change_column :users, :invitation_created_at, :datetime, precision: 6
    change_column :users, :invitation_sent_at, :datetime, precision: 6
    change_column :users, :invitation_accepted_at, :datetime, precision: 6
    change_column :users, :deleted_at, :datetime, precision: 6
    change_column :users, :last_sign_in_at, :datetime, precision: 6
    change_column :versions, :created_at, :datetime, precision: 6
  end

  def down
    disable_extension "pg_stat_statements"

    change_column :absences, :created_at, :datetime, precision: nil
    change_column :absences, :updated_at, :datetime, precision: nil
    change_column :absences, :recurrence_ends_at, :datetime, precision: nil
    change_column :agents, :reset_password_sent_at, :datetime, precision: nil
    change_column :agents, :remember_created_at, :datetime, precision: nil
    change_column :agents, :created_at, :datetime, precision: nil
    change_column :agents, :updated_at, :datetime, precision: nil
    change_column :agents, :confirmed_at, :datetime, precision: nil
    change_column :agents, :confirmation_sent_at, :datetime, precision: nil
    change_column :agents, :invitation_created_at, :datetime, precision: nil
    change_column :agents, :invitation_sent_at, :datetime, precision: nil
    change_column :agents, :invitation_accepted_at, :datetime, precision: nil
    change_column :agents, :deleted_at, :datetime, precision: nil
    change_column :agents, :current_sign_in_at, :datetime, precision: nil
    change_column :agents, :last_sign_in_at, :datetime, precision: nil
    change_column :file_attentes, :last_creneau_sent_at, :datetime, precision: nil
    change_column :lieux, :created_at, :datetime, precision: nil
    change_column :lieux, :updated_at, :datetime, precision: nil
    change_column :motifs, :created_at, :datetime, precision: nil
    change_column :motifs, :updated_at, :datetime, precision: nil
    change_column :motifs, :deleted_at, :datetime, precision: nil
    change_column :organisations, :created_at, :datetime, precision: nil
    change_column :organisations, :updated_at, :datetime, precision: nil
    change_column :plage_ouvertures, :created_at, :datetime, precision: nil
    change_column :plage_ouvertures, :updated_at, :datetime, precision: nil
    change_column :plage_ouvertures, :recurrence_ends_at, :datetime, precision: nil
    change_column :rdvs, :starts_at, :datetime, precision: nil
    change_column :rdvs, :created_at, :datetime, precision: nil
    change_column :rdvs, :updated_at, :datetime, precision: nil
    change_column :rdvs, :cancelled_at, :datetime, precision: nil
    change_column :rdvs, :ends_at, :datetime, precision: nil
    change_column :rdvs_users, :invitation_created_at, :datetime, precision: nil
    change_column :rdvs_users, :invitation_sent_at, :datetime, precision: nil
    change_column :rdvs_users, :invitation_accepted_at, :datetime, precision: nil
    change_column :super_admins, :created_at, :datetime, precision: nil
    change_column :super_admins, :updated_at, :datetime, precision: nil
    change_column :users, :created_at, :datetime, precision: nil
    change_column :users, :updated_at, :datetime, precision: nil
    change_column :users, :reset_password_sent_at, :datetime, precision: nil
    change_column :users, :remember_created_at, :datetime, precision: nil
    change_column :users, :confirmed_at, :datetime, precision: nil
    change_column :users, :confirmation_sent_at, :datetime, precision: nil
    change_column :users, :invitation_created_at, :datetime, precision: nil
    change_column :users, :invitation_sent_at, :datetime, precision: nil
    change_column :users, :invitation_accepted_at, :datetime, precision: nil
    change_column :users, :deleted_at, :datetime, precision: nil
    change_column :users, :last_sign_in_at, :datetime, precision: nil
    change_column :versions, :created_at, :datetime, precision: nil
  end
end
