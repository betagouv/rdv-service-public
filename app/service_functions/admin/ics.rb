require "icalendar"
require "icalendar/tzinfo"

module Admin::Ics
  TZID = "Europe/Paris".freeze

  def self.payload_for(object)
    send("payload_for_#{object.class.to_s.underscore}", object)
  end

  def self.create_payload_for(object)
    payload_for(object).merge(event: :create)
  end

  def self.update_payload_for(object)
    payload_for(object).merge(event: :update)
  end

  def self.destroy_payload_for(object)
    payload_for(object).merge(event: :destroy)
  end

  def self.to_ical(payload)
    send("to_ical_for_#{payload[:object]}", payload)
  end

  def self.payload_for_plage_ouverture(object)
    {
      name: "plage-ouverture-#{object.title.parameterize}-#{object.starts_at.to_s.parameterize}.ics",
      object: "plage_ouverture",
      agent_email: object.agent.email,
      starts_at: object.starts_at,
      recurrence: object.recurrence,
      ical_uid: object.ical_uid,
      title: object.title.parameterize,
      first_occurence_ends_at: object.first_occurence_ends_at,
      address: object.lieu.address
    }
  end

  def self.to_ical_for_plage_ouverture(payload)
    cal = Icalendar::Calendar.new

    tz = TZInfo::Timezone.get TZID
    timezone = tz.ical_timezone payload[:starts_at]
    cal.add_timezone timezone
    cal.prodid = BRAND
    cal.event { populate_event(_1, payload) }
    cal.ip_method = "REQUEST"
    cal.to_ical
  end

  def self.rrule(payload)
    return unless payload[:recurrence].present?

    recurrence_hash = payload[:recurrence].to_hash

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

  def self.populate_event(event, payload)
    event.uid = payload[:ical_uid]
    event.dtstart = Icalendar::Values::DateTime.new(payload[:starts_at], "tzid" => TZID)
    event.dtend = Icalendar::Values::DateTime.new(payload[:first_occurence_ends_at], "tzid" => TZID)
    event.summary = "#{BRAND} #{payload[:title]}"
    event.location = payload[:address]
    event.ip_class = "PUBLIC"
    event.rrule = rrule(payload)
    event.status = status_from_event(payload[:event])
    event.attendee = "mailto:#{payload[:agent_email]}"
  end

  def self.status_from_event(event)
    return "CANCELLED" if event == :destroy

    "CONFIRMED"
  end

  def self.by_month_day(day)
    "#{day.values.first.first}#{Date::DAYNAMES[day.keys.first][0, 2].upcase}"
  end

  def self.interval_from_hash(recurrence_hash)
    "INTERVAL=#{recurrence_hash[:interval]};" if recurrence_hash[:interval]
  end

  def self.until_from_hash(recurrence_hash)
    "UNTIL=#{Icalendar::Values::DateTime.new(recurrence_hash[:until], 'tzid' => TZID).value_ical};" if recurrence_hash[:until]
  end

  def self.by_week_day(on)
    if on.is_a?(String)
      on[0, 2].upcase
    else
      on.map { |d| d[0, 2].upcase }.join(",")
    end
  end
end
