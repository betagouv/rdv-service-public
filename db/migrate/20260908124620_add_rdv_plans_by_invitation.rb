class AddRdvPlansByInvitation < ActiveRecord::Migration[8.0]
  def change
    add_column :rdv_plans, :by_invitation, :boolean, default: false, null: false
    add_column :rdv_plans, :rdv_invitation_id, :bigint
  end
end
