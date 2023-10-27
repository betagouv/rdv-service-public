class RemoveInviteForFromUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :invite_for, :integer
  end
end
