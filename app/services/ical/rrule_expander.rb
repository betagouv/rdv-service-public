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
        modified, parents = ical_events.partition { _1.recurrence_id.present? }
        modified_dates = modified.map { |e| e.recurrence_id.to_time.to_date }

        parent = parents.first
        if parent && parent.transp != "TRANSPARENT"
          parent.occurrences_between(time_range.min, time_range.max).each do |occurrence|
            next if modified_dates.include?(occurrence.start_time.to_date)

            starts_at = occurrence.start_time.localtime
            ends_at = occurrence.end_time.localtime
            all_occurrences << Recurrence::Occurrence.new(starts_at:, ends_at:)
          end
        end

        modified.each do |ical_event|
          start_time = ical_event.dtstart.to_time
          next unless start_time >= time_range.min && start_time < time_range.max
          next if ical_event.transp == "TRANSPARENT"

          all_occurrences << Recurrence::Occurrence.new(starts_at: ical_event.dtstart.to_time, ends_at: ical_event.dtend.to_time)
        end
      end
    end

    all_occurrences.sort
  end
end
