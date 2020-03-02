class AddRecurrenceToAbsences < ActiveRecord::Migration[6.0]
  def change
    add_column :absences, :recurrence, :text
  end
end
