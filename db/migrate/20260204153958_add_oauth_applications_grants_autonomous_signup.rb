class AddOauthApplicationsGrantsAutonomousSignup < ActiveRecord::Migration[8.0]
  def up
    add_column :oauth_applications, :grants_autonomous_signup, :boolean, null: false, default: false
    OauthApplication.where.not(default_service_id: nil).update_all(grants_autonomous_signup: true)
  end

  def down
    OauthApplication.where(grants_autonomous_signup: true, default_service_id: nil).update_all(default_service_id: Service.first.id)
    remove_column :oauth_applications, :grants_autonomous_signup
  end
end
