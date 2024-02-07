class AddPrescriptionToParticipation < ActiveRecord::Migration[7.0]
  def up
    add_column :participations, :prescription, :boolean, default: false, null: false
    # Migration des données, on se base sur la valeur de created_by_type ou le fait que l'agent ne soit pas dans l'organisation du rdv
    ActiveRecord::Base.connection.execute <<-SQL.squish
      UPDATE participations
      SET prescription = TRUE
      WHERE participations.created_by_type = 'Prescripteur'
      OR (
        participations.created_by_type = 'Agent'
        AND participations.created_by_id IS NOT NULL
        AND NOT EXISTS (
          SELECT 1
          FROM agent_roles
          JOIN organisations ON organisations.id = agent_roles.organisation_id
          JOIN rdvs ON participations.rdv_id = rdvs.id
          WHERE agent_roles.agent_id = participations.created_by_id
          AND organisations.id = rdvs.organisation_id
          )
      )
    SQL
  end

  def down
    remove_column :participations, :prescription
  end
end
