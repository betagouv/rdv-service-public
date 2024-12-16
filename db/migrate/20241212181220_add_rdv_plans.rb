class AddRdvPlans < ActiveRecord::Migration[7.1]
  def change
    create_table :rdv_plans do |t|
      t.references :rdv
      t.references :agent
      t.references :rdv_agent
      t.references :motif
      t.references :lieu
      t.datetime :starts_at

      t.timestamps null: false
    end

    create_table :rdv_plan_participations do |t|
      t.references :rdv_plan
      t.references :user
      t.boolean "send_lifecycle_notifications", null: false, default: true
      t.boolean "send_reminder_notification", null: false, default: true

      t.timestamps null: false
    end
  end
end
