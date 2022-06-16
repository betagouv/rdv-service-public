# frozen_string_literal: true

class AddExternalIdsToAgentsAndOrganisations < ActiveRecord::Migration[6.1]
  def change
    add_column :agents, :external_id, :string, comment: "The agent's unique and immutable id in the system managing them and adding them to our application"
    add_index :agents, :external_id, unique: true

    add_column :organisations, :external_id, :string, comment: "The organisation's unique and immutable id in the system managing them and adding them to our application"
    add_index :organisations, :external_id, unique: true
  end
end
