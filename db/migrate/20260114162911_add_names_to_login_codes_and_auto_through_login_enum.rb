class AddNamesToLoginCodesAndAutoThroughLoginEnum < ActiveRecord::Migration[7.1]
  def change
    add_column :login_codes, :first_name, :string
    add_column :login_codes, :last_name, :string
    add_enum_value :user_created_through, "auto_through_login"
  end
end
