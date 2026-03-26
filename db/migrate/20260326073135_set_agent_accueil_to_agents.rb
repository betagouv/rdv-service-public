class SetAgentAccueilToAgents < ActiveRecord::Migration[8.0]
  def up
    # Migrer tous les rôles "basic" des agents ayant le service Secrétariat
    safety_assured do
      execute <<~SQL.squish
        UPDATE agent_roles
        SET access_level = 'agent_accueil'
        WHERE access_level = 'basic'
          AND agent_id IN (
            SELECT agent_services.agent_id
            FROM agent_services
            INNER JOIN services ON services.id = agent_services.service_id
            WHERE services.name = 'Secrétariat'
          )
      SQL
    end
  end

  def down
    safety_assured do
      execute <<~SQL.squish
        UPDATE agent_roles
        SET access_level = 'basic'
        WHERE access_level = 'agent_accueil'
      SQL
    end
  end
end
