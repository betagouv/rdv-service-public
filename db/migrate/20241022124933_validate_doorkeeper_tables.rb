class ValidateDoorkeeperTables < ActiveRecord::Migration[7.1]
  def change
    validate_foreign_key :oauth_access_grants, :oauth_applications
    validate_foreign_key :oauth_access_tokens, :oauth_applications
    validate_foreign_key :oauth_access_grants, :agents
    validate_foreign_key :oauth_access_tokens, :agents
  end
end
