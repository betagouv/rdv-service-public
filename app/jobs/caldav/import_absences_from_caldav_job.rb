module Caldav
  class ImportAbsencesFromCaldavJob < ApplicationJob
    include GoodJob::ActiveJobExtensions::Concurrency

    good_job_control_concurrency_with(
      total_limit: 1,
      key: -> { "Caldav::ImportAbsencesFromCaldavJob-#{arguments.first}" }
    )

    before_enqueue { |job| throw :abort if job.class.synced_during_last_minute?(agent_id: job.arguments.first) }
    before_perform { |job| throw :abort if job.class.synced_during_last_minute?(agent_id: job.arguments.first) }

    def self.store_latest_run_timestamp(agent_id:) = Redis.with_connection { _1.set("latest_caldav_import:#{agent_id}", Time.zone.now, ex: 1.minute) }
    def self.synced_during_last_minute?(agent_id:) = Redis.with_connection { _1.get("latest_caldav_import:#{agent_id}") }&.to_time&.after?(1.minute.ago)

    # Pour comprendre l'usage de la gem Calendav, voir la doc très claire :
    # https://github.com/pat/calendav?tab=readme-ov-file#synchronising
    #
    def perform(agent_id)
      agent = Agent.find(agent_id)
      Sentry.set_user({ id: agent.id, role: "Agent", email: agent.email })
      return unless agent.caldav_configured? || agent.caldav_disconnect_started_at.present?

      if agent.caldav_sync_token
        updated_events, deleted_events, new_sync_token = changes_since_last_sync_of(agent:)
      else
        updated_events, deleted_events, new_sync_token = all_events_for(agent:)
      end

      update_local_events_of(agent:, updated_events:, deleted_events:, new_sync_token:)

      # Import successful: set job debounce and update realtime calendars
      self.class.store_latest_run_timestamp(agent_id:)
      AgendaChannel.broadcast_to(agent_id, model: "ExternalCalendarEvent") if updated_events.any? || deleted_events.any?
    end

    private

    def changes_since_last_sync_of(agent:)
      collection = agent.caldav_client.calendars.sync(agent.caldav_agenda_url, agent.caldav_sync_token)
      new_sync_token = collection.sync_token

      # Dans les deux cas suivants, on rejette les changements qui ne sont pas des événements
      # (c’est notamment le cas des VTODO qui peuvent être mélangées avec les VEVENT dans certains serveurs Caldav)
      # On met à jour les événements modifiés qui sont « OPAQUE » (considérés comme occupés)
      updated_events = collection.changes.select { _1.calendar_data && _1.send(:inner_event) }.select { |event| consider_busy?(event) }
      # On supprime les événements modifiés qui sont « TRANSPARENT » (considérés comme libres)
      deleted_events = collection.changes.select { _1.calendar_data && _1.send(:inner_event) }.reject { |event| consider_busy?(event) }.map(&:url)

      # Le serveur Caldav de la Suite Numérique signale une suppression à travers un calendar_data vide.
      deleted_events += collection.changes.reject(&:calendar_data).map(&:url)

      # D'autres serveurs Caldav peuvent utiliser le tableau `deletions` pour signaler une suppression
      deleted_events += collection.deletions

      [updated_events, deleted_events, new_sync_token]
    end

    def all_events_for(agent:)
      new_sync_token = agent.caldav_client.calendars.find(agent.caldav_agenda_url, sync: true).sync_token
      updated_events = agent.caldav_client.events.list(agent.caldav_agenda_url) # Cette méthode ne récupère que les événements et rejette bien les VTODO
      deleted_events = []
      [updated_events, deleted_events, new_sync_token]
    end

    def update_local_events_of(agent:, updated_events:, deleted_events:, new_sync_token:)
      # On exclut le traitement des événements provenant d'un RDV de chez nous
      urls_of_rdvs = AgentsRdv.where(caldav_url: updated_events.map(&:url)).pluck(:caldav_url).to_set
      updated_events = updated_events.reject { _1.url.in?(urls_of_rdvs) }

      updated_events = updated_events.select { consider_busy?(_1) }

      ExternalCalendarEvent.transaction do
        hashes_to_upsert = updated_events.map do |event|
          raw_ical = recurring?(event) ? Ical::Scrubber.new(event.calendar_data).scrubbed : nil
          {
            agent_id: agent.id,
            url: event.url,
            starts_at: event.dtstart,
            ends_at: event.dtend,
            raw_ical:,
          }
        end

        ExternalCalendarEvent.upsert_all(hashes_to_upsert, unique_by: :index_external_calendar_events_on_agent_id_and_url) # rubocop:disable Rails/SkipsModelValidations

        ExternalCalendarEvent.where(agent: agent, url: deleted_events).delete_all if deleted_events.any?

        agent.update_columns(caldav_sync_token: new_sync_token) # rubocop:disable Rails/SkipsModelValidations
      end
    end

    def recurring?(event)
      event.send(:inner_event).rrule&.first&.valid?
    end

    # Voici comment est définit l'attribut TRANSP dans la spec iCal :
    # > TRANSP : This property defines whether an event is transparent or not to busy time searches.
    def consider_busy?(event)
      if recurring?(event)
        # Les événements récurrents peuvent être initialement TRANSPARENT
        # mais avoir des occurrences exceptionnellement OPAQUE
        event.calendar_data.include?("TRANSP:OPAQUE")
      else
        event.transp != "TRANSPARENT"
      end
    end
  end
end
