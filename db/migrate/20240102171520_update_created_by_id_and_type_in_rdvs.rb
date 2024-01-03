class UpdateCreatedByIdAndTypeInRdvs < ActiveRecord::Migration[7.0]
  def up
    # Migration des données
    # On utilise les memes valeurs pour le nouveau champ created_by_type du polymorphisme que pour l'ancien champ created_by
    # enum created_by: { agent: 0, user: 1, file_attente: 2, prescripteur: 3 }, _prefix: :created_by

    safety_assured do
      execute <<-SQL.squish
        UPDATE rdvs
        SET created_by_type = CASE
          WHEN created_by = 0 THEN 'Agent'
          WHEN created_by = 1 THEN 'User'
          WHEN created_by = 2 THEN 'FileAttente'
          WHEN created_by = 3 THEN 'Prescripteur'
        END
      SQL
    end

    # Dans le cas des rdvs created_by agents, on utilise le premier agent assigné au rdv
    safety_assured do
      execute <<-SQL.squish
        UPDATE rdvs
        SET created_by_id = (
          SELECT agents_rdvs.agent_id FROM agents_rdvs
          WHERE rdvs.id = agents_rdvs.rdv_id
          LIMIT 1
        )
        WHERE created_by = 0
      SQL
    end

    # Dans le cas des created_by users, on utilise le user de la plus ancienne participation
    safety_assured do
      execute <<-SQL.squish
        UPDATE rdvs
        SET created_by_id = (
          SELECT participations.user_id FROM participations
          WHERE rdvs.id = participations.rdv_id
          ORDER BY participations.created_at ASC
          LIMIT 1
        )
        WHERE created_by = 1
      SQL
    end

    # Dans le cas des created_by file_attentes, on utilise la file d'attente la plus ancienne
    safety_assured do
      execute <<-SQL.squish
        UPDATE rdvs
        SET created_by_id = (
          SELECT file_attentes.id FROM file_attentes
          WHERE rdvs.id  = file_attentes.rdv_id
          ORDER BY file_attentes.created_at ASC
          LIMIT 1
        )
        WHERE created_by = 2
      SQL
    end

    # Dans le cas des created_by prescripteurs, on utilise le prescripteur le plus ancien parmis les participations
    safety_assured do
      execute <<-SQL.squish
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
    end
  end

  def down
    safety_assured do
      execute <<-SQL.squish
        UPDATE rdvs
        SET created_by = CASE
          WHEN created_by_type = 'Agent' THEN 'agent'
          WHEN created_by_type = 'User' THEN 'user'
          WHEN created_by_type = 'Prescripteur' THEN 'prescripteur'
          WHEN created_by_type = 'FileAttente' THEN 'file_attente'
        END
      SQL
    end
  end
end
