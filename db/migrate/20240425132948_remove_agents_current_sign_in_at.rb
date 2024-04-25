class RemoveAgentsCurrentSignInAt < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      remove_column :agents, :current_sign_in_at, :datetime
    end
  end
end
