# frozen_string_literal: true

class AddExternalIdsToAgentsAndOrganisations < ActiveRecord::Migration[6.1]
  def change
    add_column :agents, :external_id, :string, comment: "The agent's unique and immutable id in the system managing them and adding them to our application"
    add_index :agents, :external_id

    add_column :organisations, :external_id, :string, comment: "The organisation's unique and immutable id in the system managing them and adding them to our application"
    add_index :organisations, :external_id

    # Backfill agents.external_id
    up_only do
      PaperTrail::Version.where(item_type: "Agent", event: "create").where("object_changes ilike '%conseiller-numerique.fr%'").find_each do |agent_version|
        original_agent = YAML.safe_load(agent_version.object_changes)
        agent_version.item.update_columns(external_id: original_agent["email"].presence&.last)
      end
    end
  end
end
