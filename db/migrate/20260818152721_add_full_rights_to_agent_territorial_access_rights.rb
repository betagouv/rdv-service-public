class AddFullRightsToAgentTerritorialAccessRights < ActiveRecord::Migration[8.0]
  # Le modèle AgentTerritorialRole a depuis été supprimé de l'application ; on référence donc la
  # table directement pour que cette migration reste rejouable telle quelle depuis une base vide.
  class MigrationAgentTerritorialRole < ActiveRecord::Base
    self.table_name = "agent_territorial_roles"
  end

  def up
    add_column :agent_territorial_access_rights, :full_rights, :boolean, default: false, null: false

    # Bascule des lignes agent_territorial_roles (table conservée pour le moment, mais plus
    # utilisée par l'application) vers la colonne full_rights de AgentTerritorialAccessRight.
    MigrationAgentTerritorialRole.find_each do |role|
      access_right = AgentTerritorialAccessRight.find_or_initialize_by(agent_id: role.agent_id, territory_id: role.territory_id)
      access_right.full_rights = true
      access_right.save!
    end
  end

  def down
    remove_column :agent_territorial_access_rights, :full_rights
  end
end
