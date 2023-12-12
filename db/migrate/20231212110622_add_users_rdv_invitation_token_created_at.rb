class AddUsersRdvInvitationTokenCreatedAt < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :rdv_invitation_token_created_at, :datetime
  end
end
