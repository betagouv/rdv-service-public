class ValidateRdvPlanForeignKeys < ActiveRecord::Migration[7.1]
  def change
    validate_foreign_key :rdv_plans, :agents, column: :planning_agent_id
    validate_foreign_key :rdv_plans, :agents, column: :rdv_agent_id
    validate_foreign_key :rdv_plans, :users
    validate_foreign_key :rdv_plans, :motifs
    validate_foreign_key :rdv_plans, :lieux
    validate_foreign_key :rdv_plans, :rdvs
  end
end
