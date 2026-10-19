module Caldav
  class ImportAbsencesFromCaldavJob < Caldav::BaseJob
    include GoodJob::ActiveJobExtensions::Concurrency

    good_job_control_concurrency_with(
      total_limit: 1,
      key: -> { "Caldav::ImportAbsencesFromCaldavJob-#{arguments.first}" }
    )

    before_enqueue { |job| throw :abort if job.class.synced_during_last_minute?(agent_id: job.arguments.first) }
    before_perform { |job| throw :abort if job.class.synced_during_last_minute?(agent_id: job.arguments.first) }

    def self.store_latest_run_timestamp(agent_id:)
      Redis.with_connection { _1.set("latest_caldav_import:#{agent_id}", Time.zone.now, ex: 1.minute) }
    end

    def self.synced_during_last_minute?(agent_id:)
      Redis.with_connection { _1.get("latest_caldav_import:#{agent_id}") }&.to_time&.after?(1.minute.ago)
    end

    # Pour comprendre l'usage de la gem Calendav, voir la doc très claire :
    # https://github.com/pat/calendav?tab=readme-ov-file#synchronising
    #
    def perform(agent_id)
      @agent = Agent.find(agent_id)
      Sentry.set_user({ id: @agent.id, role: "Agent", email: @agent.email })
      return unless @agent.caldav_configured?
      return if caldav_config.caldav_disconnect_started_at

      sync_logger.start!

      fetch_events_service = Caldav::FetchEvents.new(@agent, sync_logger)

      updated_events, deleted_event_urls, new_sync_token, new_ctag = fetch_events_service.fetch_changes

      update_local_events_of(updated_events:, deleted_event_urls:, new_sync_token:, new_ctag:)

      sync_logger.finalize!(successful: true)
      self.class.store_latest_run_timestamp(agent_id:)
      AgendaChannel.broadcast_to(agent_id, model: "ExternalCalendarEvent") if updated_events.any? || deleted_event_urls.any?
    rescue StandardError => e
      sync_logger.log("Error: #{e.message}")
      sync_logger.finalize!(successful: false)
      raise
    end

    private

    def update_local_events_of(updated_events:, deleted_event_urls:, new_sync_token:, new_ctag:)
      # On exclut le traitement des événements provenant d'un RDV de chez nous
      urls_of_rdvs = AgentsRdv.where(caldav_url: updated_events.map(&:url)).pluck(:caldav_url).to_set
      updated_events = updated_events.reject { _1.url.in?(urls_of_rdvs) }

      # Les événements sans DTEND (anniversaires, rappels...) ne sont pas bloquants et sont ignorés
      updated_events = updated_events.select { _1.dtend.present? }

      hashes_to_upsert = updated_events.map do |event|
        raw_ical = recurring?(event) ? Ical::Scrubber.new(event.calendar_data).scrubbed : nil
        {
          agent_id: @agent.id,
          url: event.url,
          starts_at: event.dtstart,
          ends_at: event.dtend,
          raw_ical:,
          etag: event.etag,
        }
      end

      ExternalCalendarEvent.transaction do
        ExternalCalendarEvent.upsert_all(hashes_to_upsert, unique_by: :index_external_calendar_events_on_agent_id_and_url) # rubocop:disable Rails/SkipsModelValidations

        ExternalCalendarEvent.where(agent: @agent, url: deleted_event_urls).delete_all if deleted_event_urls.any?

        caldav_config.update!(caldav_sync_token: new_sync_token, caldav_ctag: new_ctag)

        sync_logger.log("New/updated: #{updated_events.size}, deleted : #{deleted_event_urls.size}")
      end
    end

    def recurring?(event)
      event.send(:inner_event).rrule&.first&.valid?
    end

    def caldav_config
      @agent.caldav_config
    end

    def sync_logger
      @sync_logger ||= ExternalCalendarSyncExecution.new(agent_id: @agent.id, calendar_url: caldav_config.caldav_agenda_url)
    end
  end
end
