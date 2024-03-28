class CreateOrganisationMotifs < ActiveRecord::Migration[7.0]
  def change
    create_table :organisation_motifs do |t|
      t.references :organisation, foreign_key: true, index: true
      t.references :motif, foreign_key: true, index: true
      t.timestamps
    end

    reversible do |direction|
      direction.up do
        Motif.find_each do |motif|
          OrganisationMotif.create!(motif_id: motif.id, organisation_id: motif.organisation_id)
        end
      end
    end

    safety_assured do
      remove_column :motifs, :organisation_id, :integer
    end
  end
end
