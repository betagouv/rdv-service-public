class RenameMotifOnline < ActiveRecord::Migration[6.0]
  def change
    rename_column :motifs, :online, :reservable_online
  end
end
