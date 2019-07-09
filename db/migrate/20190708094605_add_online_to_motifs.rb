class AddOnlineToMotifs < ActiveRecord::Migration[5.2]
  def change
    add_column :motifs, :online, :boolean, default: false, null: false
  end
end
