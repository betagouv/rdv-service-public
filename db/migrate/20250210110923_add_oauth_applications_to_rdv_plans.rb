class AddOauthApplicationsToRdvPlans < ActiveRecord::Migration[7.1]
  def change
    add_column :rdv_plans, :oauth_application_id, :bigint
    add_foreign_key :rdv_plans, :oauth_applications, validate: false
  end
end
