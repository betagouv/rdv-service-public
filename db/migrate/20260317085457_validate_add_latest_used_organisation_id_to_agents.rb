class ValidateAddLatestUsedOrganisationIdToAgents < ActiveRecord::Migration[8.0]
  def change
    validate_foreign_key :agents, :organisations
  end
end
