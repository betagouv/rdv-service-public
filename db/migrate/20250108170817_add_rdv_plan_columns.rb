class AddRdvPlanColumns < ActiveRecord::Migration[7.1]
  def change
    add_column :rdv_plans, :duration_in_minutes, :integer
    add_column :rdv_plans, :location_type, :enum, enum_type: :location_type
  end
end
