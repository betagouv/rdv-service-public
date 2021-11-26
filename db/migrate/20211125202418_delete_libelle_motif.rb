# frozen_string_literal: true

class DeleteLibelleMotif < ActiveRecord::Migration[6.0]
  def change
    drop_table :motif_libelles do
      t.string "name"
      t.bigint "service_id", null: false
      t.datetime "created_at", precision: 6, null: false
      t.datetime "updated_at", precision: 6, null: false
      t.index ["service_id"], name: "index_motif_libelles_on_service_id"
    end
  end
end
