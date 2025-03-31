class AddOauthApplicationsDefaultServiceId < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :oauth_applications, :default_service_id, :bigint
    add_index :oauth_applications, :default_service_id, algorithm: :concurrently
    add_foreign_key :oauth_applications, :services, validate: false, column: :default_service_id

    change_column_comment :oauth_applications, :default_service_id, from: nil, to: <<~COMMENT
      Indique le service qui sera ajouté au territoire par défaut si un agent qui utilise cette application ouvre un nouvel espace.
      Cette colonne indique aussi que les agents qui utilisent cette application sont autorisés à ouvrir un nouvel espace.
    COMMENT

    up_only do
      app = OauthApplication.find_by(name: "Mon Suivi Social")
      service = Service.find_by(name: "Action Sociale")
      if app && service
        app.update(default_service_id: service.id)
      end
    end
  end
end
