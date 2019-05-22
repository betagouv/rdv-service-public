class AddConfirmableToDevise < ActiveRecord::Migration[5.2]

  def up
    add_column :pros, :confirmation_token, :string
    add_column :pros, :confirmed_at, :datetime
    add_column :pros, :confirmation_sent_at, :datetime
    add_column :pros, :unconfirmed_email, :string
    add_index :pros, :confirmation_token, unique: true
    Pro.update_all confirmed_at: DateTime.now
  end

  def down
    remove_columns :pros, :confirmation_token, :confirmed_at, :confirmation_sent_at, :unconfirmed_email
  end

end
