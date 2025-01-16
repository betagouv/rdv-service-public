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
      t.integer :duration_in_minutes
      t.text :return_url

      t.timestamps null: false
    end

    change_column_comment :rdv_plans, :rdv_agent_id, from: nil, to: "L'id de l'agent qui assurera le rdv"
    change_column_comment :rdv_plans, :planning_agent_id, from: nil, to: "L'id de l'agent qui planifie le rdv"

    add_foreign_key :rdv_plans, :agents, column: :planning_agent_id, validate: false
    add_foreign_key :rdv_plans, :agents, column: :rdv_agent_id, validate: false
    add_foreign_key :rdv_plans, :users, validate: false
    add_foreign_key :rdv_plans, :rdvs, validate: false
    add_foreign_key :rdv_plans, :motifs, validate: false
    add_foreign_key :rdv_plans, :lieux, validate: false
  end
end
