class AddFullRightsToAgentTerritorialAccessRights < ActiveRecord::Migration[8.0]
  # Le modèle AgentTerritorialRole a depuis été supprimé de l'application ; on référence donc la
  # table directement pour que cette migration reste rejouable telle quelle depuis une base vide.
  class MigrationAgentTerritorialRole < ActiveRecord::Base
    self.table_name = "agent_territorial_roles"
  end

  def up
    add_column :agent_territorial_access_rights, :territory_admin, :boolean, default: false, null: false

    # Bascule des lignes agent_territorial_roles (table conservée pour le moment, mais plus
    # utilisée par l'application) vers la colonne territory_admin de AgentTerritorialAccessRight.
    now = Time.current
    rows = MigrationAgentTerritorialRole.pluck(:agent_id, :territory_id).map do |agent_id, territory_id|
      { agent_id: agent_id, territory_id: territory_id, territory_admin: true, created_at: now, updated_at: now }
    end

    AgentTerritorialAccessRight.upsert_all(rows, unique_by: %i[agent_id territory_id], update_only: [:territory_admin]) if rows.any?
  end

  def down
    # Bascule inverse : recrée les lignes agent_territorial_roles correspondant aux
    # AgentTerritorialAccessRight ayant territory_admin: true.
    rows = AgentTerritorialAccessRight.where(territory_admin: true).pluck(:agent_id, :territory_id).map do |agent_id, territory_id|
      { agent_id: agent_id, territory_id: territory_id }
    end

    MigrationAgentTerritorialRole.upsert_all(rows, unique_by: %i[agent_id territory_id]) if rows.any?

    remove_column :agent_territorial_access_rights, :territory_admin
  end
end
