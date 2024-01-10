class AddCreatedByFields < ActiveRecord::Migration[7.0]
  def change
    add_column :participations, :created_by_id, :integer
    add_column :participations, :created_by_type, :string

    change_column_null :participations, :created_by, true
    change_column_null :prescripteurs, :participation_id, true

    add_column :rdvs, :created_by_id, :integer
    add_column :rdvs, :created_by_type, :string
  end

  private

  # À lancer dans un container après que la migration Rails soit passée
  def migration_des_donnees
    # --- Migration des participations ---
    #
    # On utilise les memes valeurs pour le nouveau champ created_by_type du polymorphisme que pour l'ancien champ created_by
    ActiveRecord::Base.connection.execute <<-SQL.squish
      UPDATE participations
      SET created_by_type = CASE
        WHEN created_by = 'agent' THEN 'Agent'
        WHEN created_by = 'user' THEN 'User'
        WHEN created_by = 'prescripteur' THEN 'Prescripteur'
      END
    SQL

    # POUR L'INSTANT, PAS DE MIGRATION DE L'HISTORIQUE POUR LES AGENTS (VOIR PR)

    # Dans le cas des users, on utilise le user de la participation
    ActiveRecord::Base.connection.execute <<-SQL.squish
      UPDATE participations
      SET created_by_id = user_id
      WHERE created_by = 'user'
    SQL

    # Dans le cas des prescripteurs, on utilise le prescripteur de la participation
    ActiveRecord::Base.connection.execute <<-SQL.squish
      UPDATE participations
      SET created_by_id = (
        SELECT prescripteurs.id FROM prescripteurs
        WHERE prescripteurs.participation_id = participations.id
      )
      WHERE created_by = 'prescripteur'
    SQL

    # ROLLBACK
    ActiveRecord::Base.connection.execute <<-SQL.squish
      UPDATE participations
      SET created_by = CASE
        WHEN created_by_type = 'Agent' THEN (CAST('agent' AS created_by))
        WHEN created_by_type = 'User' THEN (CAST('user' AS created_by))
        WHEN created_by_type = 'Prescripteur' THEN (CAST('prescripteur' AS created_by))
      END
    SQL

    # --- Migration des rdvs ---

    # On utilise les memes valeurs pour le nouveau champ created_by_type du polymorphisme que pour l'ancien champ created_by
    # enum created_by: { agent: 0, user: 1, file_attente: 2, prescripteur: 3 }, _prefix: :created_by
    ActiveRecord::Base.connection.execute <<-SQL.squish
      UPDATE rdvs
      SET created_by_type = CASE
        WHEN created_by = 0 THEN 'Agent'
        WHEN created_by = 1 THEN 'User'
        WHEN created_by = 2 THEN 'FileAttente'
        WHEN created_by = 3 THEN 'Prescripteur'
      END
    SQL

    # POUR L'INSTANT, PAS DE MIGRATION DE L'HISTORIQUE POUR LES AGENTS (VOIR PR)
    #
    # Dans le cas des created_by users, on utilise le user de la plus ancienne participation
    ActiveRecord::Base.connection.execute <<-SQL.squish
      UPDATE rdvs
      SET created_by_id = (
        SELECT participations.user_id FROM participations
        WHERE rdvs.id = participations.rdv_id
        ORDER BY participations.created_at ASC
        LIMIT 1
      )
      WHERE created_by = 1
    SQL

    # Dans le cas des created_by file_attentes, on utilise la file d'attente la plus ancienne
    ActiveRecord::Base.connection.execute <<-SQL.squish
      UPDATE rdvs
      SET created_by_id = (
        SELECT file_attentes.id FROM file_attentes
        WHERE rdvs.id  = file_attentes.rdv_id
        ORDER BY file_attentes.created_at ASC
        LIMIT 1
      )
      WHERE created_by = 2
    SQL

    # Dans le cas des created_by prescripteurs, on utilise le prescripteur le plus ancien parmis les participations
    ActiveRecord::Base.connection.execute <<-SQL.squish
      UPDATE rdvs
      SET created_by_id = (
        SELECT prescripteurs.id FROM prescripteurs
        JOIN participations ON rdvs.id = participations.rdv_id
        WHERE prescripteurs.participation_id = participations.id
        ORDER BY prescripteurs.created_at ASC
        LIMIT 1
      )
      WHERE created_by = 3
    SQL

    # ROLLBACK
    ActiveRecord::Base.connection.execute <<-SQL.squish
      UPDATE rdvs
      SET created_by = CASE
        WHEN created_by_type = 'Agent' THEN 0
        WHEN created_by_type = 'User' THEN 1
        WHEN created_by_type = 'FileAttente' THEN 2
        WHEN created_by_type = 'Prescripteur' THEN 3
      END
    SQL
  end
end
