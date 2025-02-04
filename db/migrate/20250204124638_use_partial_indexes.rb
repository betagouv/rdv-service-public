class UsePartialIndexes < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    # Vérifié sur un dump de prod : la majorité des expired_cached sont
    # à true et donc un WHERE IS TRUE utilise un seq scan.
    change_to_partial_index(:plage_ouvertures, :expired_cached, where: "IS FALSE")
    change_to_partial_index(:absences, :expired_cached, where: "IS FALSE")

    # Je pense inutile, car aussi coûteux qu'un seq scan et
    # la table est très étroite (3 petites colonnes)
    remove_index :agent_roles, :access_level

    # déjà géré par un index composite
    remove_index :agent_roles, :organisation_id
    remove_index :agent_services, :agent_id
    remove_index :agent_teams, :team_id
    remove_index :agent_territorial_access_rights, :agent_id
    remove_index :agent_territorial_roles, :agent_id
    remove_index :agents_rdvs, :agent_id
    remove_index :file_attentes, :rdv_id
    remove_index :motifs_plage_ouvertures, :motif_id
    remove_index :organisations, :name
    remove_index :participations, :rdv_id
    remove_index :referent_assignations, :user_id
    remove_index :sectors, :human_id
    remove_index :territory_services, :territory_id
    remove_index :users, :invitations_count # Toutes les lignes sont à 0, il faudrait supprimer la colonne
    remove_index :webhook_endpoints, :organisation_id

    # Colonnes essentiellement vides, pas la peine d'indexer les NULL
    change_to_partial_index(:agents, :account_deletion_warning_sent_at)
    change_to_partial_index(:agents, :calendar_uid, unique: true)
    change_to_partial_index(:agents, :confirmation_token, unique: true)
    change_to_partial_index(:agents, :external_id, unique: true)
    change_to_partial_index(:agents, :invitation_token, unique: true)
    change_to_partial_index(:agents, :reset_password_token, unique: true)
    change_to_partial_index(:motifs, :deleted_at)
    change_to_partial_index(:participations, :invitation_token, unique: true)
    change_to_partial_index(:rdv_plans, :lieu_id)
    change_to_partial_index(:rdv_plans, :motif_id)
    change_to_partial_index(:rdv_plans, :planning_agent_id)
    change_to_partial_index(:rdv_plans, :rdv_agent_id)
    change_to_partial_index(:rdv_plans, :rdv_id)
    change_to_partial_index(:rdv_plans, :user_id)
    change_to_partial_index(:rdvs, :lieu_id)
    change_to_partial_index(:rdvs, :max_participants_count)
    change_to_partial_index(:users, :birth_date)
    change_to_partial_index(:users, :confirmation_token, unique: true)
    change_to_partial_index(:users, :phone_number_formatted)
    change_to_partial_index(:users, :rdv_invitation_token, unique: true)
    change_to_partial_index(:users, :reset_password_token, unique: true)
    change_to_partial_index(:users, :responsible_id)

    change_to_partial_index(:agents, :invitations_count, where: "!= 0")
    change_to_partial_index(:motifs, :collectif, where: "IS TRUE")

    # On a un seul where sur cette colonne, pour ne pas afficher les RDVs de
    # motifs invisibles sur la liste des RDVs de usagers. Dans cette requête,
    # on a déjà filtré sur les RDVs de l'usager, donc cet index n'est même pas utilisé.
    # Je pense que ça été ajouté par principe mais sans compréhension fine dans
    # https://github.com/betagouv/rdv-service-public/pull/2285#discussion_r831427307
    remove_index :motifs, :visibility_type

    # Entropie trop faible, et ne fait jamais un where sur le status de beaucoup de participations.
    remove_index :participations, :status

    remove_index :participations, %i[created_by_type created_by_id]
    add_index :participations,    %i[created_by_type created_by_id], where: "(created_by_id IS NOT NULL)", algorithm: :concurrently

    remove_index :participations, :invited_by_id
    remove_index :participations, %i[invited_by_type invited_by_id], name: "index_participations_on_invited_by"
    add_index :participations,    %i[invited_by_type invited_by_id], where: "(invited_by_id IS NOT NULL)", algorithm: :concurrently

    remove_index :rdvs, %i[created_by_type created_by_id]
    add_index :rdvs,    %i[created_by_type created_by_id], where: "(created_by_id IS NOT NULL)", algorithm: :concurrently

    remove_index :users, :invited_by_id
    remove_index :users,  %i[invited_by_type invited_by_id]
    add_index :users,     %i[invited_by_type invited_by_id], where: "(invited_by_id IS NOT NULL)", algorithm: :concurrently
  end

  private

  def change_to_partial_index(table, column, where: "IS NOT NULL", unique: false)
    remove_index table, column, unique: unique
    add_index table, column, where: "(#{column} #{where})", unique: unique, algorithm: :concurrently
  end
end
