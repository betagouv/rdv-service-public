class AddContactEmailToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :contact_email, :string
  end
end
