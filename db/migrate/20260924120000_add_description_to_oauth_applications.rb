class AddDescriptionToOauthApplications < ActiveRecord::Migration[8.0]
  def change
    add_column :oauth_applications, :description, :text
  end
end
