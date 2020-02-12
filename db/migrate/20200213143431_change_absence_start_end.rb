class ChangeAbsenceStartEnd < ActiveRecord::Migration[6.0]
  require 'tod/core_extensions'

  def up
    add_column :absences, :first_day, :date
    add_column :absences, :start_time, :time
    add_column :absences, :end_day, :date
    add_column :absences, :end_time, :time

    Absence.all.each do |a|
      a.first_day = a[:starts_at].to_date
      a.start_time = a[:starts_at].to_time_of_day

      a.end_day = a[:ends_at].to_date
      a.end_time = a[:ends_at].to_time_of_day
      a.save!
    end

    change_column :absences, :first_day, :date, null: false
    change_column :absences, :start_time, :time, null: false
    change_column :absences, :end_day, :date, null: false
    change_column :absences, :end_time, :time, null: false

    remove_column :absences, :starts_at
    remove_column :absences, :ends_at
  end

  def down
    add_column :absences, :starts_at, :datetime
    add_column :absences, :ends_at, :datetime

    Absence.all.each do |a|
      a.starts_at = a.start_time.on(a.first_day)
      a.ends_at = a.end_time.on(a.end_day)
      a.save!
    end

    remove_column :absences, :first_day
    remove_column :absences, :start_time
    remove_column :absences, :end_day
    remove_column :absences, :end_time
  end
end
