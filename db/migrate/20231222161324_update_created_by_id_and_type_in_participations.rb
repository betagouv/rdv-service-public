class UpdateCreatedByIdAndTypeInParticipations < ActiveRecord::Migration[7.0]
  def up
    # Migration des données
    # On utilise les memes valeurs pour le nouveau champ created_by_type du polymorphisme que pour l'ancien champ created_by
    safety_assured do
      execute <<-SQL.squish
        UPDATE participations
        SET created_by_type = CASE
          WHEN created_by = 'agent' THEN 'Agent'
          WHEN created_by = 'user' THEN 'User'
          WHEN created_by = 'prescripteur' THEN 'Prescripteur'
        END
      SQL
    end

    # Dans le cas des agents, on utilise le premier agent assigné au rdv
    safety_assured do
      execute <<-SQL.squish
        UPDATE participations
        SET created_by_id = (
          SELECT agents_rdvs.agent_id FROM agents_rdvs
          JOIN rdvs ON rdvs.id = agents_rdvs.rdv_id
          WHERE rdvs.id = participations.rdv_id
          LIMIT 1
        )
        WHERE created_by = 'agent'
      SQL
    end

    # Dans le cas des users, on utilise le user de la participation
    safety_assured do
      execute <<-SQL.squish
        UPDATE participations
        SET created_by_id = user_id
        WHERE created_by = 'user'
      SQL
    end

    # Dans le cas des prescripteurs, on utilise le prescripteur de la participation
    safety_assured do
      execute <<-SQL.squish
        UPDATE participations
        SET created_by_id = (
          SELECT prescripteurs.id FROM prescripteurs
          WHERE prescripteurs.participation_id = participations.id
        )
        WHERE created_by = 'prescripteur'
      SQL
    end
  end

  def down
    safety_assured do
      execute <<-SQL.squish
        UPDATE participations
        SET created_by = CASE
          WHEN created_by_type = 'Agent' THEN 'agent'
          WHEN created_by_type = 'User' THEN 'user'
          WHEN created_by_type = 'Prescripteur' THEN 'prescripteur'
        END
      SQL
    end
  end
end
