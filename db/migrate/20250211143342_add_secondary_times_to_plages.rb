class AddSecondaryTimesToPlages < ActiveRecord::Migration[7.1]
  def change
    add_column :plage_ouvertures, :secondary_start_time, :time
    add_column :plage_ouvertures, :secondary_end_time,   :time
  end
end
