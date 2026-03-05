class AddLatestUsedOrganisationIdToAgents < ActiveRecord::Migration[8.0]
  def change
    add_column :agents, :latest_used_organisation_id, :bigint
    add_foreign_key :agents, :organisations, column: :latest_used_organisation_id, validate: false
  end
end
