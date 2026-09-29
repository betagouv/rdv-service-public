class AddMenshenAccessTokenToAgents < ActiveRecord::Migration[8.0]
  def change
    add_column :agents, :menshen_access_token, :text
    add_column :agents, :menshen_access_token_expires_at, :datetime
  end
end
