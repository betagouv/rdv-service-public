class PlagesOuverturesTitleCanBeNull < ActiveRecord::Migration[7.1]
  def change
    change_column_null :plage_ouvertures, :title, true
  end
end
