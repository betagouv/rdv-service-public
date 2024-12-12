class AddRdvPlans < ActiveRecord::Migration[7.1]
  def change
    create_table :rdv_plans do |t|
      t.references :rdv
      t.references :agent
      t.references :motif
      t.references :lieu
      t.datetime :starts_at

      t.timestamps null: false
    end

    create_table :rdv_plan_participations do |t|
      t.references :rdv_plan
      t.references :user

      t.timestamps null: false
    end
  end
end
