# frozen_string_literal: true

require "icalendar/tzinfo"

module IcalHelpers
  module Ics
    def to_ical(*args)
      IcalHelpers::Ics.from_payload(payload(*args))
    end

    def self.from_payload(payload)
      cal = Icalendar::Calendar.new

      cal.add_timezone Time.zone_default.tzinfo.ical_timezone payload[:starts_at]
      cal.prodid = BRAND
      cal.event { |event| populate_event(event, payload) }

      cal.to_ical
    end

    def self.populate_event(event, payload)
      event.uid = payload[:ical_uid]
      if payload[:action].present?
        event.status = (payload[:action] == :destroy ? "CANCELLED" : "CONFIRMED")
      end
      if payload[:starts_at].present?
        dtstart = Icalendar::Values::DateTime.new(payload[:starts_at],
                                                  "tzid" => Time.zone_default.tzinfo.identifier)
        event.dtstart = dtstart
      end
      if payload[:ends_at].present?
        dtend = Icalendar::Values::DateTime.new(payload[:ends_at],
                                                "tzid" => Time.zone_default.tzinfo.identifier)
        event.dtend = dtend
      end
      event.summary = payload[:summary]
      event.location = payload[:address]
      event.rrule = payload[:recurrence]
      event.sequence = payload[:sequence]
      event.description = payload[:description]
    end
  end
end
