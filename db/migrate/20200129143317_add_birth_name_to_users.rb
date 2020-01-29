class AddBirthNameToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :birth_name, :string
  end
end
