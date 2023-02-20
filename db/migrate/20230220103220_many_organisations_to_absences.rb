# frozen_string_literal: true

class ManyOrganisationsToAbsences < ActiveRecord::Migration[7.0]
  def change
    # creer table abs-organisations => jointure entre les deux
    create_join_table :absences, :organisations do |t|
      t.index %i[absence_id organisation_id], unique: true
    end

    # reprendre toutes les anciennes jointure
    # pour chaque abs = > creer enregistement dans table de jointure

    # 345k abs le 13 fevrier 2023 (à conserver)

    Absence.all.find_in_batches do |absences_batch|
      reversible do |direction|
        direction.up do
          attrs = absences_batch.map do |absence|
            { absence_id: absence.id, organisation_id: absence.organisation_id }
          end

          AbsencesOrganisation.insert_all(attrs, unique_by: %i[absence_id organisation_id])
        end
        direction.down do
          attrs = absences_batch.map do |absence|
            { id: absence.id, organisation_id: absence.organisations.first.id }
          end

          Absence.upsert_all(attrs)
        end
      end
    end

    # supprimer jointure
    remove_column :absences, :organisation_id
  end
end
