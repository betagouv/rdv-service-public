class RemoveDefaultOnPlageOuvertureRecurrence < ActiveRecord::Migration[5.2]
  def change
    change_column_default(:plage_ouvertures, :recurrence, nil)
  end
end
