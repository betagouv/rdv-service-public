class AddCancelledAtToRdv < ActiveRecord::Migration[5.2]
  def change
    add_column :rdvs, :cancelled_at, :datetime
  end
end
