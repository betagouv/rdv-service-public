class RenameSitesToLieux < ActiveRecord::Migration[5.2]
  def change
    rename_table :sites, :lieux
  end
end
