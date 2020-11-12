class AddWebsiteAndEmailToOrganisation < ActiveRecord::Migration[6.0]
  def change
    add_column :organisations, :website, :string
    add_column :organisations, :email, :string
  end
end
