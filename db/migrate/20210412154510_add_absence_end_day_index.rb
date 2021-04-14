class AddAbsenceEndDayIndex < ActiveRecord::Migration[6.0]
  def change
    add_index :absences, :end_day
  end
end
