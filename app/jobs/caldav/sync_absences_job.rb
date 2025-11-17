module Caldav
  class SyncAbsencesJob < ApplicationJob
    # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    def perform(agent_id)
      return if synced_during_last_minute?(agent_id)

      @agent = Agent.find_by_id(agent_id)
      return unless @agent&.caldav_configured? || @agent&.caldav_disconnect_in_progress?

      Sentry.set_user({ id: @agent.id, role: "Agent", email: @agent.email })

      if @agent.caldav_sync_token.present?
        collection = @agent.caldav_client.calendars.sync(@agent.caldav_agenda_url, @agent.caldav_sync_token)
        collection.changes.each do |event|
          if event.calendar_data.nil?
            Absence.where(agent: @agent, caldav_url: event.url).destroy_all
          else
            upsert_absence(event)
          end
        end
        @agent.update!(caldav_sync_token: collection.sync_token)
      else
        sync_token = @agent.caldav_client.calendars.find(@agent.caldav_agenda_url, sync: true).sync_token
        events = @agent.caldav_client.events.list(@agent.caldav_agenda_url)

        events.each do |event|
          upsert_absence(event)
        end
        @agent.update!(caldav_sync_token: sync_token)
      end
    end
    # rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity

    private

    def upsert_absence(event)
      return if AgentsRdv.exists?(caldav_url: event.url) # On ne fait rien si il s’agit d’un événement provenant de chez nous
      return if event.dtstart < Time.now.in_time_zone # On ne gère pas les absences passées

      absence = Absence.find_or_initialize_by(agent: @agent, caldav_url: event.url)

      # TODO: gérer les événements récurrents
      absence.assign_attributes(
        first_day: event.dtstart.to_date,
        end_day: event.dtend.to_date,
        start_time: event.dtstart,
        end_time: event.dtend,
        title: "Indisponibilité provenant de votre agenda externe"
      )
      absence.save! if absence.changed?
    end

    def synced_during_last_minute?(agent_id)
      Redis.with_connection do |redis|
        redis.set("caldav_sync_absences_job_lock_#{agent_id}", true, ex: 1.minute.to_i, nx: true) == false
      end
    end
  end
end
