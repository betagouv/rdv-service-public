class AddAgentAccueilEnabledToOrganisations < ActiveRecord::Migration[8.0]
  def up
    add_column :organisations, :agent_accueil_enabled, :boolean, default: false, null: false

    safety_assured do
      execute <<~SQL.squish
        UPDATE organisations
        SET agent_accueil_enabled = true
        WHERE territory_id IN (
          SELECT territory_services.territory_id
          FROM territory_services
          INNER JOIN services ON services.id = territory_services.service_id
          WHERE services.name = 'Secrétariat'
        )
      SQL
    end
  end

  def down
    remove_column :organisations, :agent_accueil_enabled
  end
end
