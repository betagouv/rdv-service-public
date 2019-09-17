class AddDeletedAtToMotifs < ActiveRecord::Migration[5.2]
  def change
    add_column :motifs, :deleted_at, :datetime
  end
end
