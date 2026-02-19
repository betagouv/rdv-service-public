class RemoveCaldavUrlFromAbsences < ActiveRecord::Migration[8.0]
  def change
    safety_assured { remove_column :absences, :caldav_url, :string }
  end
end
