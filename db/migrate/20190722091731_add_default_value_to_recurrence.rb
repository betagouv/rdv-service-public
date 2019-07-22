class AddDefaultValueToRecurrence < ActiveRecord::Migration[5.2]
  def change
    change_column :plage_ouvertures, :recurrence, :text, default: PlageOuverture::RECURRENCES[:never]
  end
end
