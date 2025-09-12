class AddDefaultLieuxAvailability < ActiveRecord::Migration[7.2]
  def change
    change_column_default :lieux, :availability, from: nil, to: :enabled
  end
end
