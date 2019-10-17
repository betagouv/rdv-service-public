class RenameProToAgent < ActiveRecord::Migration[6.0]
  def change
    rename_table :pros, :agents
  end
end
