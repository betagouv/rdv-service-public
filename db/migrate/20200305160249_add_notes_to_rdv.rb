class AddNotesToRdv < ActiveRecord::Migration[6.0]
  def change
    add_column :rdvs, :notes, :text
  end
end
