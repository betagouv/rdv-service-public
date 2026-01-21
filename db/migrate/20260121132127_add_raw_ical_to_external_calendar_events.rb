class AddRawIcalToExternalCalendarEvents < ActiveRecord::Migration[8.0]
  def change
    up_only do
      ExternalCalendarEvent.delete_all

      Agent.where.not(caldav_agenda_url: nil).each do |agent|
        agent.update!(caldav_sync_token: nil)
        Caldav::ImportAbsencesFromCaldavJob.perform_later(agent.id)
      end
    end

    add_column :external_calendar_events, :raw_ical, :text

    # Au passage, j'avais oublié cet index lors de la création de la table.
    safety_assured do # La table contient au plus 2000 lignes, ce n'est pas grave de bloquer l'écriture pendant quelques ms.
      add_index :external_calendar_events, %i[agent_id url], unique: true
    end
  end
end
