class AddHorairesToSite < ActiveRecord::Migration[5.2]
  def change
    add_column :sites, :horaires, :text
  end
end
