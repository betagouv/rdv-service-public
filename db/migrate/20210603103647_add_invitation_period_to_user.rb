class AddInvitationPeriodToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :invitation_validity_period, :integer
  end
end
