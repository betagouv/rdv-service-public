class RemoveInvitationsCountColumns < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    safety_assured do
      remove_index :agents, :invitations_count, algorithm: :concurrently
      remove_index :users, :invitations_count, algorithm: :concurrently

      remove_column :agents,          :invitations_count, :integer, default: 0
      remove_column :users,           :invitations_count, :integer, default: 0
      remove_column :participations,  :invitations_count, :integer, default: 0

      remove_index :agents, :inclusion_connect_open_id_sub, unique: true, where: "inclusion_connect_open_id_sub IS NOT NULL", algorithm: :concurrently
      remove_column :agents, :inclusion_connect_open_id_sub, :string
    end
  end
end
