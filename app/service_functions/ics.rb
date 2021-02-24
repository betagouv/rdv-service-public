require "icalendar"
require "icalendar/tzinfo"

module Ics
  TZID = "Europe/Paris".freeze

  def self.payload_for(object, event)
    send("payload_for_#{object.class.to_s.underscore}", object, event)
  end

  def self.to_ical(payload)
    send("to_ical_for_#{payload[:object]}", payload)
  end

  def self.payload_for_plage_ouverture(object, event)
    {
      name: "plage-ouverture-#{object.title.parameterize}-#{object.starts_at.to_s.parameterize}.ics",
      object: "plage_ouverture",
      event: event,
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

  def self.populate_event(event, payload)
    event.uid         = payload[:ical_uid]
    event.dtstart     = Icalendar::Values::DateTime.new(payload[:starts_at], "tzid" => TZID)
    event.dtend       = Icalendar::Values::DateTime.new(payload[:first_occurence_ends_at], "tzid" => TZID)
    event.summary     = "#{BRAND} #{payload[:title]}"
    event.location    = payload[:address]
    event.ip_class    = "PUBLIC"
    event.attendee    = "mailto:#{payload[:agent_email]}"
    event.rrule       = rrule(payload)
    event.status = "CANCELLED" if payload[:event] == "destroy"
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
end
