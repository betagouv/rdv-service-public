class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.references :organisation, foreign_key: true
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :address
      t.string :phone_number
      t.date :birth_date
      t.timestamps
    end
  end
end
