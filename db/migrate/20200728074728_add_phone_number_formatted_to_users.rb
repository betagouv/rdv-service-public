class AddPhoneNumberFormattedToUsers < ActiveRecord::Migration[6.0]
  def up
    add_column :users, :phone_number_formatted, :string

    User.where.not(phone_number: nil).where.not(phone_number: "").each do |user|
      user.update_columns(phone_number_formatted: Phonelib.parse(user.phone_number).e164)
    end
  end

  def down
    remove_column :users, :phone_number_formatted
  end
end
