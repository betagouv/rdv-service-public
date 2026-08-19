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
    MigrationAgentTerritorialRole.find_each do |role|
      access_right = AgentTerritorialAccessRight.find_or_initialize_by(agent_id: role.agent_id, territory_id: role.territory_id)
      access_right.territory_admin = true
      access_right.save!
    end
  end

  def down
    # Bascule inverse : recrée les lignes agent_territorial_roles correspondant aux
    # AgentTerritorialAccessRight ayant territory_admin: true.
    AgentTerritorialAccessRight.where(territory_admin: true).find_each do |access_right|
      MigrationAgentTerritorialRole.find_or_create_by!(agent_id: access_right.agent_id, territory_id: access_right.territory_id)
    end

    remove_column :agent_territorial_access_rights, :territory_admin
  end
end
