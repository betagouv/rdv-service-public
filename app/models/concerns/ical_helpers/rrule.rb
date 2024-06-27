module IcalHelpers
  module Rrule
    def rrule
      IcalHelpers::Rrule.from_recurrence(recurrence)
    end

    def self.from_recurrence(recurrence)
      return if recurrence.blank?

      case recurrence[:every]
      when "week"
        freq = "FREQ=WEEKLY;"
        by_day = "BYDAY=#{by_week_day(recurrence[:on].compact_blank)};" if recurrence[:on]
      when "month"
        freq = "FREQ=MONTHLY;"
        by_day = "BYDAY=#{by_month_day(recurrence[:day].compact_blank)};" if recurrence[:day]
      end

      interval = interval_from_hash(recurrence)

      until_date = until_from_hash(recurrence)

      "#{freq}#{interval}#{by_day}#{until_date}"
    end

    def self.by_month_day(day)
      "#{day.values.first.first}#{Date::DAYNAMES[day.keys.first][0, 2].upcase}"
    end

    def self.interval_from_hash(recurrence)
      "INTERVAL=#{recurrence[:interval]};" if recurrence[:interval]
    end

    def self.until_from_hash(recurrence)
      "UNTIL=#{Icalendar::Values::DateTime.new(recurrence[:until], 'tzid' => Time.zone_default.tzinfo.identifier).value_ical};" if recurrence[:until]
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
