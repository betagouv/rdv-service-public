class AddMinMaxBookinDelayToMotifs < ActiveRecord::Migration[5.2]
  def change
    add_column :motifs, :min_booking_delay, :integer, default: 30.minutes
    add_column :motifs, :max_booking_delay, :integer, default: 3.months
  end
end
