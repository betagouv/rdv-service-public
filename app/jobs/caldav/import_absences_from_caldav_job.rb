module Caldav
  class ImportAbsencesFromCaldavJob < ApplicationJob
    include GoodJob::ActiveJobExtensions::Concurrency

    good_job_control_concurrency_with(
      perform_limit: 1,
      key: -> { "Caldav::ImportAbsencesFromCaldavJob-#{arguments.first}" }
    )

    before_enqueue do |job|
      throw :abort if synced_during_last_minute?(job.arguments.first)
    end

    # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    def perform(agent_id)
      @agent = Agent.find_by_id(agent_id)
      return unless @agent&.caldav_configured? || @agent&.caldav_disconnect_in_progress?

      Sentry.set_user({ id: @agent.id, role: "Agent", email: @agent.email })

      if @agent.caldav_sync_token.present?
        collection = @agent.caldav_client.calendars.sync(@agent.caldav_agenda_url, @agent.caldav_sync_token)
        events = collection.changes
        Absence.transaction do
          events.each do |event|
            if event.calendar_data.nil?
              Absence.where(agent: @agent, caldav_url: event.url).delete_all
            else
              upsert_absence(event)
            end
          end
          @agent.update_columns(caldav_sync_token: collection.sync_token) # rubocop:disable Rails/SkipsModelValidations
        end
      else
        sync_token = @agent.caldav_client.calendars.find(@agent.caldav_agenda_url, sync: true).sync_token
        events = @agent.caldav_client.events.list(@agent.caldav_agenda_url)

        Absence.transaction do
          events.each do |event|
            upsert_absence(event)
          end
          @agent.update_columns(caldav_sync_token: sync_token) # rubocop:disable Rails/SkipsModelValidations
        end
      end
    end
    # rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity

    private

    def upsert_absence(event)
      return if AgentsRdv.exists?(caldav_url: event.url) # On ne fait rien si il s’agit d’un événement provenant de chez nous
      return if event.dtstart < (Time.now.in_time_zone - 1.week).beginning_of_week # On ne gère pas les absences passées

      Absence.transaction do
        Absence.where(agent: @agent, caldav_url: event.url).delete_all

        from = 1.month.ago
        to = 1.month.from_now
        absence_hashes = Caldav::RruleExpander.call(ical_calendar: event.calendar_data, from:, to:).map do |recurrence|
          {
            agent_id: @agent.id,
            caldav_url: event.url,

            first_day: recurrence.starts_at.to_date,
            start_time: recurrence.starts_at,

            end_day: recurrence.ends_at.to_date,
            end_time: recurrence.ends_at,

            title: "Indisponibilité provenant d’un agenda externe",
          }
        end
        Absence.insert_all!(absence_hashes) # rubocop:disable Rails/SkipsModelValidations
      end
    end

    def synced_during_last_minute?(agent_id)
      Redis.with_connection do |redis|
        redis.set("caldav_sync_absences_job_lock_#{agent_id}", true, ex: 1.minute.to_i, nx: true) == false
      end
    end
  end
end
