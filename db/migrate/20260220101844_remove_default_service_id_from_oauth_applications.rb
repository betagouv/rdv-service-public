class RemoveDefaultServiceIdFromOauthApplications < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    safety_assured do
      remove_column :oauth_applications, :default_service_id
    end
  end

  def down
    add_column :oauth_applications, :default_service_id, :bigint
    add_index :oauth_applications, :default_service_id, algorithm: :concurrently
    add_foreign_key :oauth_applications, :services, column: :default_service_id
    change_column_comment :oauth_applications, :default_service_id, from: nil, to: <<~COMMENT
      Indique le service qui sera ajouté au territoire par défaut si un agent qui utilise cette application ouvre un nouvel espace.
      Cette colonne indique aussi que les agents qui utilisent cette application sont autorisés à ouvrir un nouvel espace.
    COMMENT
  end
end
