class AddCaldavUrlInAbsences < ActiveRecord::Migration[7.2]
  def change
    add_column :absences, :caldav_url, :string
  end
end
