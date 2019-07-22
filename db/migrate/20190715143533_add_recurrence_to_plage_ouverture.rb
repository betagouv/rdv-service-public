class AddRecurrenceToPlageOuverture < ActiveRecord::Migration[5.2]
  def change
    add_column :plage_ouvertures, :recurrence, :text
  end
end
