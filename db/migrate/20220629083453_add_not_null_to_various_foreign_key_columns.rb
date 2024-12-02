class AddNotNullToVariousForeignKeyColumns < ActiveRecord::Migration[6.1]
  def change
    change_column_null :absences, :agent_id, false
    change_column_null :absences, :organisation_id, false
    change_column_null :agent_teams, :agent_id, false
    change_column_null :agent_teams, :team_id, false
    change_column_null :agent_territorial_roles, :agent_id, false
    change_column_null :agents, :service_id, false
    change_column_null :agents_organisations, :agent_id, false
    change_column_null :agents_organisations, :organisation_id, false
    change_column_null :agents_rdvs, :agent_id, false
    change_column_null :agents_rdvs, :rdv_id, false
    change_column_null :agents_users, :agent_id, false
    change_column_null :agents_users, :user_id, false
    change_column_null :motifs, :organisation_id, false
    change_column_null :motifs, :service_id, false
    change_column_null :motifs_plage_ouvertures, :motif_id, false
    change_column_null :motifs_plage_ouvertures, :plage_ouverture_id, false
    change_column_null :plage_ouvertures, :agent_id, false
    change_column_null :plage_ouvertures, :organisation_id, false
    change_column_null :plage_ouvertures, :lieu_id, false
    change_column_null :rdvs, :organisation_id, false
    change_column_null :rdvs, :motif_id, false
    change_column_null :rdvs_users, :rdv_id, false
    change_column_null :rdvs_users, :user_id, false
    change_column_null :receipts, :rdv_id, false
    change_column_null :teams, :territory_id, false
    change_column_null :user_profiles, :user_id, false
    change_column_null :user_profiles, :organisation_id, false
  end
  # rubocop:enable Metrics/MethodLength
end
