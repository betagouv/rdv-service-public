class AddPotentialDuplicateUserToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :potential_duplicate_id, :integer, index: true, foreign_key: true
  end
end
