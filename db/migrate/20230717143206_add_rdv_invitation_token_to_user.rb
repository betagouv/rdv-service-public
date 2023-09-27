# frozen_string_literal: true

class AddRdvInvitationTokenToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :rdv_invitation_token, :string
    add_index :users, :rdv_invitation_token, unique: true

    # Existing invitation_token will be migrated using this export from rdv-insertion
    # array = []
    # Invitation.valid.each do |invitation|
    #   array << { user_id: invitation.applicant.rdv_solidarites_user_id, rdv_invitation_token: invitation.rdv_solidarites_token }
    # end

    # Import array in rdv-sp database
    # array.each do |element|
    #   user = User.find_by(id: element[:user_id])
    #   user.update(rdv_invitation_token: element[:rdv_invitation_token]) if user.present?
    # end
  end
end
