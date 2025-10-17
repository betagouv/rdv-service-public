class AddWorkOnSundayInTerritory < ActiveRecord::Migration[7.2]
  def change
    add_column :territories, :work_on_sunday, :boolean, default: false

    up_only do
      Territory.where(name: Territory::VISIOPLAINTE_NAME).update_all(work_on_sunday: true)
    end
  end
end
