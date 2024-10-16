class RemoveUserAndAgentsRememberCreatedAt < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      remove_column :users, :remember_created_at, :datetime
      remove_column :agents, :remember_created_at, :datetime
    end
  end
end
