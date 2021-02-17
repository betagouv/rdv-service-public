class AddLoggedOnceWithFranceconnectToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :logged_once_with_franceconnect, :boolean
  end
end
