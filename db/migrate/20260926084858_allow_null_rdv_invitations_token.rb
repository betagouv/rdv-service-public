class AllowNullRdvInvitationsToken < ActiveRecord::Migration[8.0]
  def change
    change_column_null :rdv_invitations, :token, true
    change_column_null :rdv_invitations, :motif_id, true
  end
end
