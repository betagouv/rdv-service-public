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
      fetch_events_service.fetch_changes

      update_local_events!(fetch_events_service)

      sync_logger.finalize!(successful: true)
      self.class.store_latest_run_timestamp(agent_id:)
      AgendaChannel.broadcast_to(agent_id, model: "ExternalCalendarEvent") if fetch_events_service.any_changes?
    rescue StandardError => e
      sync_logger.log("Error: #{e.message}")
      sync_logger.finalize!(successful: false)
      raise
    end

    private

    def update_local_events!(fetch_events_service)
      upserted_count = 0

      # Les lots sont produits à la volée (avec des requêtes HTTP pour certains serveurs) : on les upserte
      # hors transaction pour ne pas garder une connexion à la base ouverte pendant ces appels réseau.
      # Chaque upsert est atomique et idempotent, et le ctag / sync token n'est mis à jour qu'à la fin :
      # en cas d'échec en cours de route, la prochaine synchro reprend ce qui manque.
      fetch_events_service.each_updated_batch do |updated_events|
        # On exclut le traitement des événements provenant d'un RDV de chez nous
        urls_of_rdvs = AgentsRdv.where(caldav_url: updated_events.map(&:url)).pluck(:caldav_url).to_set
        hashes_to_upsert = updated_events.reject { _1.url.in?(urls_of_rdvs) }.map { _1.to_external_calendar_event_hash(@agent.id) }
        next if hashes_to_upsert.empty?

        ExternalCalendarEvent.upsert_all(hashes_to_upsert, unique_by: :index_external_calendar_events_on_agent_id_and_url) # rubocop:disable Rails/SkipsModelValidations
        upserted_count += hashes_to_upsert.size
      end

      # Les suppressions ne sont connues en entier qu'une fois tous les lots traités
      deleted_event_urls = fetch_events_service.deleted_event_urls

      ExternalCalendarEvent.transaction do
        ExternalCalendarEvent.where(agent: @agent, url: deleted_event_urls).delete_all if deleted_event_urls.any?

        caldav_config.update!(caldav_sync_token: fetch_events_service.new_sync_token, caldav_ctag: fetch_events_service.new_ctag)

        sync_logger.log("New/updated: #{upserted_count}, deleted : #{deleted_event_urls.size}")
      end
    end

    def caldav_config
      @agent.caldav_config
    end

    def sync_logger
      @sync_logger ||= ExternalCalendarSyncExecution.new(agent_id: @agent.id, calendar_url: caldav_config.caldav_agenda_url)
    end
  end
end
