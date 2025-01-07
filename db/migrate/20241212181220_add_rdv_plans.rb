class AddRdvPlans < ActiveRecord::Migration[7.1]
  def change
    create_table :rdv_plans do |t|
      t.references :planning_agent
      t.references :rdv
      t.references :user
      t.references :rdv_agent
      t.references :motif
      t.references :lieu
      t.datetime :starts_at

      t.timestamps null: false
    end

    change_column_comment :rdv_plans, :rdv_agent_id, from: nil, to: "L'id de l'agent qui assurera le rdv"
    change_column_comment :rdv_plans, :planning_agent_id, from: nil, to: "L'id de l'agent qui planifie le rdv"
  end
end
