class ValidateOauthApplicationDefaultService < ActiveRecord::Migration[7.1]
  def change
    validate_foreign_key :oauth_applications, :services
  end
end
