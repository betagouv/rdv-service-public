class RemoveRdvsSequence < ActiveRecord::Migration[7.0]
  def change
    remove_column :rdvs, :sequence, :integer, default: 0, null: false
  end
end
