class AddRawIcalToExternalCalendarEvents < ActiveRecord::Migration[8.0]
  def change
    # On vide les données en début de migration pour les re-remplir à la fin (en up comme en down)
    agents_with_caldav = Agent.where.not(caldav_agenda_url: nil)
    agents_with_caldav.update_all(caldav_sync_token: nil)
    ExternalCalendarEvent.delete_all

    add_column :external_calendar_events, :raw_ical, :text

    # On re-remplit les données via les jobs asynchrones
    agents_with_caldav.each do |agent|
      Caldav::ImportAbsencesFromCaldavJob.perform_later(agent.id)
    end
  end
end
