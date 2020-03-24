class PlageOuverture::Ics
  include ActiveModel::Model
  attr_accessor :plage_ouverture
  validates :plage_ouverture, presence: true

  TZID = "Europe/Paris".freeze

  def to_ical
    require 'icalendar'
    require 'icalendar/tzinfo'

    cal = Icalendar::Calendar.new

    tz = TZInfo::Timezone.get TZID
    timezone = tz.ical_timezone plage_ouverture.starts_at
    cal.add_timezone timezone

    cal.event do |e|
      e.dtstart     = Icalendar::Values::DateTime.new(plage_ouverture.starts_at, 'tzid' => TZID)
      e.dtend       = Icalendar::Values::DateTime.new(plage_ouverture.ends_at, 'tzid' => TZID)
      e.summary     = "#{BRAND} #{plage_ouverture.title}"
      e.description = ""
      e.location    = plage_ouverture.lieu.address
      e.ip_class    = "PUBLIC"
      e.attendee    = "mailto:#{plage_ouverture.agent.email}"
      e.rrule       = rrule
    end

    cal.ip_method = "REQUEST"
    cal.to_ical
  end

  def rrule
    return unless plage_ouverture.recurrence.present?

    recurrence_hash = plage_ouverture.recurrence.to_hash

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

  def name
    "plage-ouverture-#{plage_ouverture.title.parameterize}-#{plage_ouverture.starts_at.to_s.parameterize}.ics"
  end

  private

  def until_from_hash(recurrence_hash)
    "UNTIL=#{Icalendar::Values::DateTime.new(recurrence_hash[:until], "tzid" => TZID).value_ical};" if recurrence_hash[:until]
  end

  def interval_from_hash(recurrence_hash)
    "INTERVAL=#{recurrence_hash[:interval]};" if recurrence_hash[:interval]
  end

  def by_week_day(on)
    if on.is_a?(String)
      on[0, 2].upcase
    else
      on.map { |d| d[0, 2].upcase }.join(',')
    end
  end

  def by_month_day(day)
    "#{day.values.first.first}#{Date::DAYNAMES[day.keys.first][0, 2].upcase}"
  end
end
