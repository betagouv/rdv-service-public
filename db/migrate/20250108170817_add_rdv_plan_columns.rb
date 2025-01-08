class AddRdvPlanColumns < ActiveRecord::Migration[7.1]
  def change
    add_columns :rdv_plans, :duration_in_minutes, type: :integer
  end
end
