class AddRestrictionAndInstructionToMotif < ActiveRecord::Migration[6.0]
  def change
    add_column :motifs, :restriction_for_rdv, :text
    add_column :motifs, :instruction_for_rdv, :text
  end
end
