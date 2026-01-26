class Ical::RruleExpander
  def initialize(raw_ical)
    @raw_ical = raw_ical
  end

  def all_occurrences_within(time_range) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    all_occurrences = []
    calendars = Icalendar::Calendar.parse(@raw_ical)
    calendars.each do |calendar|
      events_by_uid = calendar.events.group_by { |e| e.uid.to_s }

      # On suppose que ça n'arrivera jamais, mais on commence par débugger.
      # TODO: Supprimer ou adapter un mois après déploiement en prod.
      Sentry.capture_message("DEBUG: Plusieurs UIDs détectés") if events_by_uid.size > 1

      events_by_uid.each_value do |ical_events|
        parent = ical_events.reject(&:recurrence_id).sole
        exceptions = ical_events.select(&:recurrence_id)

        exception_dates = exceptions.map { |e| e.recurrence_id.to_time.to_date }

        if parent && parent.transp != "TRANSPARENT"
          parent.occurrences_between(time_range.min, time_range.max).each do |occurrence|
            next if exception_dates.include?(occurrence.start_time.to_date)

            starts_at = occurrence.start_time.localtime
            ends_at = occurrence.end_time.localtime
            all_occurrences << Recurrence::Occurrence.new(starts_at:, ends_at:)
          end
        end

        exceptions.each do |exception_ical_event|
          start_time = exception_ical_event.dtstart.to_time
          next if exception_ical_event.transp == "TRANSPARENT"
          next unless start_time >= time_range.min && start_time < time_range.max

          all_occurrences << Recurrence::Occurrence.new(starts_at: exception_ical_event.dtstart.to_time, ends_at: exception_ical_event.dtend.to_time)
        end
      end
    end

    all_occurrences.sort
  end
end
