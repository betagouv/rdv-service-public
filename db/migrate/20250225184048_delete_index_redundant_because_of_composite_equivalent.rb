class DeleteIndexRedundantBecauseOfCompositeEquivalent < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    # Tous ces index sont redondants, car il existe pour chacun le même index
    # en version composite, c'est-à-dire sur cette colonne + une autre.
    remove_index :agent_roles, :organisation_id, algorithm: :concurrently
    remove_index :agent_services, :agent_id, algorithm: :concurrently
    remove_index :agent_teams, :team_id, algorithm: :concurrently
    remove_index :agent_territorial_access_rights, :agent_id, algorithm: :concurrently
    remove_index :agent_territorial_roles, :agent_id, algorithm: :concurrently
    remove_index :agents_rdvs, :agent_id, algorithm: :concurrently
    remove_index :file_attentes, :rdv_id, algorithm: :concurrently
    remove_index :motifs_plage_ouvertures, :motif_id, algorithm: :concurrently
    remove_index :organisations, :name, algorithm: :concurrently
    remove_index :participations, :rdv_id, algorithm: :concurrently
    remove_index :referent_assignations, :user_id, algorithm: :concurrently
    remove_index :sectors, :human_id, algorithm: :concurrently
    remove_index :territory_services, :territory_id, algorithm: :concurrently
    remove_index :webhook_endpoints, :organisation_id, algorithm: :concurrently
  end
end
