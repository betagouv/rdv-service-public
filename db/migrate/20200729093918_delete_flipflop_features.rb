class DeleteFlipflopFeatures < ActiveRecord::Migration[6.0]
  def up
    drop_table :flipflop_features
  end
end
