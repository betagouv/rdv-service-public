class ValidateRdvInvitationForeignKeys < ActiveRecord::Migration[8.0]
  def change
    validate_foreign_key :rdv_invitations, :agents
    validate_foreign_key :rdv_invitations, :lieux
    validate_foreign_key :rdv_invitations, :motifs
    validate_foreign_key :rdv_invitations, :rdvs
    validate_foreign_key :rdv_invitations, :users
  end
end
