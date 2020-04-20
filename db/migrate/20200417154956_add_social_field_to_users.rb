class AddSocialFieldToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :working_status, :integer
    add_column :users, :resource_origin, :string
    add_column :users, :resource_amount, :float
    add_column :users, :rental_charge, :float
    add_column :users, :conjoint_full_name, :string
    add_column :users, :conjoint_birth_date, :date
  end
end
