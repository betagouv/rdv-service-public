# frozen_string_literal: true

class DropRdvEvent < ActiveRecord::Migration[6.1]
  def change
    drop_table "rdv_events" do |t|
      t.bigint "rdv_id", null: false
      t.string "event_type"
      t.string "event_name"
      t.datetime "created_at"
      t.index ["rdv_id"], name: "index_rdv_events_on_rdv_id"
    end
  end
end
