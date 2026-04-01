class SetAgentAccueilToAgents < ActiveRecord::Migration[8.0]
  def up
    # Mettre agent_accueil = true pour tous les agents ayant le service Secrétariat
    safety_assured do
      execute <<~SQL.squish
        UPDATE agent_roles
        SET agent_accueil = true
        WHERE agent_id IN (
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
        SET agent_accueil = false
      SQL
    end
  end
end
