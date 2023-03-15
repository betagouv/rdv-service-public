# frozen_string_literal: true

class BackfillMotifsBookableBy < ActiveRecord::Migration[7.0]
  def up
    Motif.where(bookable_publicly: true).update_all(bookable_by: :agents_and_prescripteurs_and_users)
    Motif.where(bookable_publicly: false).update_all(bookable_by: :agents)
  end

  def down
    Motif.where(bookable_by: :agents_and_prescripteurs_and_users).update_all(bookable_publicly: true)
    Motif.where(bookable_by: %i[agents agents_and_prescripteurs]).update_all(bookable_publicly: false)
  end
end
