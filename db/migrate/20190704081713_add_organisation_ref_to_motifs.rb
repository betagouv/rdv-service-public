class AddOrganisationRefToMotifs < ActiveRecord::Migration[5.2]
  def change
    add_reference :motifs, :organisation, foreign_key: true
  end
end
