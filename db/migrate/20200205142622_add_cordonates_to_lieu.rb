class AddCordonatesToLieu < ActiveRecord::Migration[6.0]
  def change
    add_column :lieux, :latitude, :float
    add_column :lieux, :longitude, :float
  end
end
