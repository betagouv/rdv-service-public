class AddWorkOnSundayInTerritory < ActiveRecord::Migration[7.2]
  def change
    add_column :territories, :work_on_sunday, :boolean, default: false
  end
end
