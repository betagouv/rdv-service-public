class AddUsersRdvInvitationTokenUpdatedAt < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :rdv_invitation_token_updated_at, :datetime
  end
end
