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
      Redis.with_connection do |redis|
        latest_run = redis.get("caldav_sync_absences_job_debounce_#{agent_id}")
        latest_run && latest_run < 1.minute.ago
      end
    end

    # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    def perform(agent_id)
      @agent = Agent.find_by_id(agent_id)
      return unless @agent&.caldav_configured? || @agent&.caldav_disconnect_in_progress?

      Sentry.set_user({ id: @agent.id, role: "Agent", email: @agent.email })

      if @agent.caldav_sync_token.present?
        collection = @agent.caldav_client.calendars.sync(@agent.caldav_agenda_url, @agent.caldav_sync_token)
        events = collection.changes
        ExternalCalendarEvent.transaction do
          events.each do |event|
            if event.calendar_data.nil?
              ExternalCalendarEvent.where(agent: @agent, url: event.url).delete_all
            else
              upsert_event(event)
            end
          end
          @agent.update_columns(caldav_sync_token: collection.sync_token) # rubocop:disable Rails/SkipsModelValidations
        end
      else
        sync_token = @agent.caldav_client.calendars.find(@agent.caldav_agenda_url, sync: true).sync_token
        events = @agent.caldav_client.events.list(@agent.caldav_agenda_url)

        ExternalCalendarEvent.transaction do
          events.each do |event|
            upsert_event(event)
          end
          @agent.update_columns(caldav_sync_token: sync_token) # rubocop:disable Rails/SkipsModelValidations
        end
      end

      Redis.with_connection do |redis|
        redis.set("caldav_sync_absences_job_debounce_#{agent_id}", Time.zone.now)
      end
    end
    # rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity

    private

    def upsert_event(event)
      return if AgentsRdv.exists?(caldav_url: event.url) # On ne fait rien si il s’agit d’un événement provenant de chez nous

      recurring = event.send(:inner_event).rrule.first.valid?

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
