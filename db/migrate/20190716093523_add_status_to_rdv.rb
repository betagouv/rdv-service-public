class AddStatusToRdv < ActiveRecord::Migration[5.2]
  def change
    add_column :rdvs, :status, :integer, default: 0
  end
end
