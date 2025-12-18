class Caldav::RruleExpander
  CACHE_FILE = "calendar_cache.json".freeze
  def self.call(ical_calendar:, from:, to:) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    all_occurrences = []
    calendars = Icalendar::Calendar.parse(ical_calendar)
    calendars.each do |calendar|
      events_by_uid = calendar.events.group_by { |e| e.uid.to_s }

      events_by_uid.each_value do |ical_events|
        modified, parent = ical_events.partition { _1.recurrence_id.present? }

        modified_dates = modified.map { |e| e.recurrence_id.to_time.to_date }

        parent = parent.first
        parent&.occurrences_between(from, to)&.each do |occurrence|
          next if modified_dates.include?(occurrence.start_time.to_date)

          starts_at = occurrence.start_time.localtime
          ends_at = occurrence.end_time.localtime
          all_occurrences << Recurrence::Occurrence.new(starts_at:, ends_at:)
        end

        modified.each do |ical_event|
          start_time = ical_event.dtstart.to_time
          next unless start_time >= from && start_time < to

          all_occurrences << Recurrence::Occurrence.new(starts_at: ical_event.dtstart, ends_at: ical_event.dtend)
        end
      end
    end

    all_occurrences.sort
  end
end
