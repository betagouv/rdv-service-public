module Caldav
  class ImportAbsencesFromCaldavJob < ApplicationJob
    include GoodJob::ActiveJobExtensions::Concurrency

    good_job_control_concurrency_with(
      perform_limit: 1,
      key: -> { "Caldav::ImportAbsencesFromCaldavJob-#{arguments.first}" }
    )

    before_enqueue do |job|
      throw :abort if job.class.synced_during_last_minute?(job.arguments.first)
    end

    def self.synced_during_last_minute?(agent_id)
      Redis.with_connection { |redis| redis.get("caldav_sync_absences_job_debounce_#{agent_id}") }
    end

    # Pour comprendre l'usage de la gem Calendav, voir la doc très claire :
    # https://github.com/pat/calendav?tab=readme-ov-file#synchronising
    #
    # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    def perform(agent_id)
      @agent = Agent.find_by_id(agent_id)
      return unless @agent&.caldav_configured? || @agent&.caldav_disconnect_in_progress?

      Sentry.set_user({ id: @agent.id, role: "Agent", email: @agent.email })

      if @agent.caldav_sync_token
        collection = @agent.caldav_client.calendars.sync(@agent.caldav_agenda_url, @agent.caldav_sync_token)

        # Le serveur Caldav de la Suite Numérique signale une suppression à travers un calendar_data vide.
        updated_events = collection.changes.select(&:calendar_data)
        deleted_events = collection.changes.reject(&:calendar_data).map(&:url)

        # D'autres serveurs Caldav peuvent utiliser le tableau `deletions` pour signaler une suppression
        deleted_events += collection.deletions

        update_local_data(updated_events:, deleted_events:, new_sync_token: collection.sync_token)
      else
        new_sync_token = @agent.caldav_client.calendars.find(@agent.caldav_agenda_url, sync: true).sync_token
        updated_events = @agent.caldav_client.events.list(@agent.caldav_agenda_url)
        deleted_events = []
        update_local_data(updated_events:, deleted_events:, new_sync_token:)
      end

      # Import successful
      set_debounce
      live_update_calendar if updated_events.any? || deleted_events.any?
    end
    # rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity

    private

    def update_local_data(updated_events:, deleted_events:, new_sync_token:)
      # On exclut le traitement des événements provenant d'un RDV de chez nous
      urls_of_rdvs = AgentsRdv.where(caldav_url: updated_events.map(&:url)).pluck(:caldav_url)
      updated_events = updated_events.reject { _1.url == urls_of_rdvs }

      ExternalCalendarEvent.transaction do
        updated_events.each { |event| upsert_event(event) }

        ExternalCalendarEvent.where(agent: @agent, url: deleted_events).delete_all if deleted_events.any?

        @agent.update_columns(caldav_sync_token: new_sync_token) # rubocop:disable Rails/SkipsModelValidations
      end
    end

    def set_debounce
      Redis.with_connection { |redis| redis.set("caldav_sync_absences_job_debounce_#{@agent.id}", true, ex: 1.minute) }
    end

    def live_update_calendar
      AgendaChannel.broadcast_to(@agent.id, model: "ExternalCalendarEvent")
    end

    def upsert_event(event)
      recurring = event.send(:inner_event).rrule&.first&.valid?

      e = ExternalCalendarEvent.find_or_initialize_by(agent: @agent, url: event.url)
      e.assign_attributes(
        starts_at: event.dtstart,
        ends_at: event.dtend,
        raw_ical: recurring ? event.calendar_data : nil
      )
      e.save!
    end
  end
end
