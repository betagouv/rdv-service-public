class AddParticipationRestrictedAuthToken < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :participations, :restricted_auth_token, :text

    add_index :participations, :restricted_auth_token, where: "(restricted_auth_token IS NOT NULL)", algorithm: :concurrently
  end
end
