class AddIndexToRdvsUuid < ActiveRecord::Migration[7.0]
  def change
    add_index :rdvs, :uuid
  end
end
