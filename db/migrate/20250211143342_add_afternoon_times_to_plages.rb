class AddAfternoonTimesToPlages < ActiveRecord::Migration[7.1]
  def change
    add_column :plage_ouvertures, :afternoon_start_time, :time
    add_column :plage_ouvertures, :afternoon_end_time,   :time
  end
end
