class AddAgentIdAndGrantTypeToOauthApplications < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  # safety_assured : la table oauth_applications est petite, la FK est posée avec on_delete: :nullify
  # et l'index est créé concurrently
  safety_assured do
    add_reference :oauth_applications, :agent, index: { algorithm: :concurrently }, foreign_key: { on_delete: :nullify }
    add_column :oauth_applications, :grant_type, :string, default: "authorization_code", null: false
    change_column_null :oauth_applications, :redirect_uri, true
  end
end
