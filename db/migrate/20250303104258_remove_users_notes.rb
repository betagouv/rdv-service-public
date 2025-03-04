class RemoveUsersNotes < ActiveRecord::Migration[7.1]
  def change
    safety_assured do
      remove_column :users, :notes, :text
    end
  end
end
