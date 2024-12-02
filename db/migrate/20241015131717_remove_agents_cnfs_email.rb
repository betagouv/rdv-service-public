class RemoveAgentsCnfsEmail < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      remove_column :agents, :cnfs_secondary_email, :string
    end
  end
end
