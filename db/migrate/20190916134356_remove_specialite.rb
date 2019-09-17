class RemoveSpecialite < ActiveRecord::Migration[6.0]
  def change
    remove_reference :motifs, :specialite, index: true
    remove_reference :pros, :specialite, index: true
    drop_table :specialites
  end
end
