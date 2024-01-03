class RemoveParticipationAssociationFromPrescripteurs < ActiveRecord::Migration[7.0]
  def up
    safety_assured { remove_column :prescripteurs, :participation_id }
  end

  def down
    add_column :prescripteurs, :participation_id, :bigint

    safety_assured do
      execute <<-SQL.squish
            UPDATE prescripteurs
            SET participation_id = (
              SELECT participations.id FROM participations
              WHERE created_by_type = 'Prescripteur'
              AND created_by_id = prescripteurs.id
              LIMIT 1
            )
      SQL
    end
  end
end
