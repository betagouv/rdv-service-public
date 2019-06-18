class ChangeDefaultDurationForRdv < ActiveRecord::Migration[5.2]
  def change
    change_column_default(:rdvs, :duration_in_min, nil)
  end
end
