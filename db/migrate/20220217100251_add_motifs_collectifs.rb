class AddMotifsCollectifs < ActiveRecord::Migration[6.1]
  def change
    add_column :motifs, :collectif, :boolean, default: false
  end
end
