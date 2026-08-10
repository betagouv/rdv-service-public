class AddInvitationTokensToRdvPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :rdv_plans, :invitation_token, :text
  end
end
