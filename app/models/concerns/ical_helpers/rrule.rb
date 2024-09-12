module IcalHelpers
  module Rrule
    def self.from_recurrence(recurrence)
      return if recurrence.blank?

      recurrence_hash = recurrence.to_hash

      case recurrence_hash[:every]
      when :week
        freq = "FREQ=WEEKLY;"
        by_day = "BYDAY=#{by_week_day(recurrence_hash[:on])};" if recurrence_hash[:on]
      when :month
        freq = "FREQ=MONTHLY;"
        by_day = "BYDAY=#{by_month_day(recurrence_hash[:day])};" if recurrence_hash[:day]
      end

      interval = interval_from_hash(recurrence_hash)

      until_date = until_from_hash(recurrence_hash)

      "#{freq}#{interval}#{by_day}#{until_date}"
    end

    def self.by_month_day(day)
      "#{day.values.first.first}#{Date::DAYNAMES[day.keys.first][0, 2].upcase}"
    end

    def self.interval_from_hash(recurrence_hash)
      "INTERVAL=#{recurrence_hash[:interval]};" if recurrence_hash[:interval]
    end

    def self.until_from_hash(recurrence_hash)
      "UNTIL=#{Icalendar::Values::DateTime.new(recurrence_hash[:until], 'tzid' => Time.zone_default.tzinfo.identifier).value_ical};" if recurrence_hash[:until]
    end

    def self.by_week_day(on)
      if on.is_a?(String)
        on[0, 2].upcase
      else
        on.map { |d| d[0, 2].upcase }.join(",")
      end
    end
  end
end
