class AddFollowUpToMotifs < ActiveRecord::Migration[6.0]
  def change
    add_column :motifs, :follow_up, :boolean, default: false
  end
end
