class CreateLoginCodes < ActiveRecord::Migration[8.0]
  def change
    create_table :login_codes do |t|
      t.string :email, null: false
      t.string :code, null: false
      t.string :domain_id, null: false
      t.datetime :used_at

      t.timestamps

      t.index %i[email created_at]
    end
  end
end
