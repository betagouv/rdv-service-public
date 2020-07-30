class CreateRdvEvents < ActiveRecord::Migration[6.0]
  def change
    create_table :rdv_events do |t|
      t.references :rdv, null: false, foreign_key: true
      t.string :event_type
      t.string :event_name
      t.datetime :created_at
    end
  end
end
