class AddInternalDocumentationToOauthApplications < ActiveRecord::Migration[8.0]
  def change
    add_column :oauth_applications, :internal_documentation, :text
  end
end
