# frozen_string_literal: true

class BackfillMotifsBookableBy < ActiveRecord::Migration[7.0]
  def up
    Motif.where(bookable_publicly: true).update_all(bookable_by: :everyone)
    Motif.where(bookable_publicly: false).update_all(bookable_by: :agents)
    rename_column :motifs, :bookable_publicly, :legacy_bookable_publicly
  end

  def down
    rename_column :motifs, :legacy_bookable_publicly, :bookable_publicly
    Motif.where(bookable_by: :everyone).update_all(bookable_publicly: true)
    Motif.where(bookable_by: %i[agents agents_and_prescripteurs]).update_all(bookable_publicly: false)
  end
end
