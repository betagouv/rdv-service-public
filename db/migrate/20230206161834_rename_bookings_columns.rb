# frozen_string_literal: true

class RenameBookingsColumns < ActiveRecord::Migration[7.0]
  def change
    rename_column :motifs, :min_booking_delay, :min_public_booking_delay
    rename_column :motifs, :max_booking_delay, :max_public_booking_delay
    rename_column :motifs, :reservable_online, :bookable_publicly
  end
end
