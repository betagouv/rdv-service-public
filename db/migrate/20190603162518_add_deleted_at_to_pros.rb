class AddDeletedAtToPros < ActiveRecord::Migration[5.2]
  def change
    add_column :pros, :deleted_at, :datetime
  end
end
