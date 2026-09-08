class ValidateRdvPlansRdvInvitationIndexAndKey < ActiveRecord::Migration[8.0]
  def change
    validate_foreign_key :rdv_plans, :rdv_invitations
  end
end
