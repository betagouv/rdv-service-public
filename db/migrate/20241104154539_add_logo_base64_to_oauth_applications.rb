class AddLogoBase64ToOauthApplications < ActiveRecord::Migration[7.1]
  def change
    add_column :oauth_applications, :logo_base64, :text
  end
end
