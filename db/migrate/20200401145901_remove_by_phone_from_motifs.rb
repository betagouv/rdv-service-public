class RemoveByPhoneFromMotifs < ActiveRecord::Migration[6.0]
  def change
    remove_column :motifs, :by_phone
  end
end
