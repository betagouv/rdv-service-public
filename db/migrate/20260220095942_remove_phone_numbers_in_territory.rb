class RemovePhoneNumbersInTerritory < ActiveRecord::Migration[8.0]
  def change
    safety_assured do
      remove_column :territories, :phone_number, :string
      remove_column :territories, :phone_number_formatted, :string
    end
  end
end
