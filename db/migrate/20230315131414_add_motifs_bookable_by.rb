# frozen_string_literal: true

class AddMotifsBookableBy < ActiveRecord::Migration[7.0]
  def change
    create_enum :bookable_by, %i[agents agents_and_prescripteurs agents_and_prescripteurs_and_users]
    add_column :motifs, :bookable_by, :bookable_by, null: false, default: :agents
  end
end
