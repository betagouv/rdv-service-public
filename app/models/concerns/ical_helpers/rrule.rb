module IcalHelpers
  module Rrule
    def rrule
      IcalHelpers::Rrule.from_recurrence(schedule)
    end

    def self.from_recurrence(schedule)
      return if schedule.blank?

      schedule_hash = schedule.to_hash

      case schedule_hash[:every]
      when :week
        freq = "FREQ=WEEKLY;"
        by_day = "BYDAY=#{by_week_day(schedule_hash[:on])};" if schedule_hash[:on]
      when :month
        freq = "FREQ=MONTHLY;"
        by_day = "BYDAY=#{by_month_day(schedule_hash[:day])};" if schedule_hash[:day]
      end

      interval = interval_from_hash(schedule_hash)

      until_date = until_from_hash(schedule_hash)

      "#{freq}#{interval}#{by_day}#{until_date}"
    end

    def self.by_month_day(day)
      "#{day.values.first.first}#{Date::DAYNAMES[day.keys.first][0, 2].upcase}"
    end

    def self.interval_from_hash(schedule_hash)
      "INTERVAL=#{schedule_hash[:interval]};" if schedule_hash[:interval]
    end

    def self.until_from_hash(schedule_hash)
      "UNTIL=#{Icalendar::Values::DateTime.new(schedule_hash[:until], 'tzid' => Time.zone_default.tzinfo.identifier).value_ical};" if schedule_hash[:until]
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
