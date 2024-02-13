class RemoveUnusedAgentIpColumns < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      remove_column :agents,  :current_sign_in_ip, :string
      remove_column :agents,  :last_sign_in_ip, :string
      remove_column :agents,  :sign_in_count, :integer
    end
  end
end
