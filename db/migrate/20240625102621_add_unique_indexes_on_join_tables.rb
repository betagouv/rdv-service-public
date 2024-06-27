class AddUniqueIndexesOnJoinTables < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    add_index :agent_teams, %i[team_id agent_id], unique: true, name: :index_agent_teams_primary_keys, algorithm: :concurrently
    add_index :motifs_plage_ouvertures, %i[motif_id plage_ouverture_id], unique: true, name: :index_motifs_plage_ouvertures_primary_keys, algorithm: :concurrently
  end
end
