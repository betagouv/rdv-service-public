class AddRdvPlansRdvInvitationIdIndex < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :rdv_plans, :rdv_invitation_id, algorithm: :concurrently
    add_foreign_key :rdv_plans, :rdv_invitations, validate: false
  end
end
