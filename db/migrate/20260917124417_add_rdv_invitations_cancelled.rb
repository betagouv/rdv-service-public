class AddRdvInvitationsCancelled < ActiveRecord::Migration[8.0]
  def change
    add_column :rdv_invitations, :cancelled, :boolean, default: false, null: false
  end
end
