# frozen_string_literal: true

require "icalendar/tzinfo"

module IcalHelpers
  module Ics
    def to_ical(*args)
      IcalHelpers::Ics.from_payload(payload(*args)).to_ical
    end

    # Specs
    # iCalendar: https://datatracker.ietf.org/doc/html/rfc5545#section-3.6.1
    #   * See section 3.6.1 for VEVENT
    # iTIP: https://datatracker.ietf.org/doc/html/rfc2446#section-3.2
    #   * See section 3.2 for the semantics of the METHOD
    #
    # See also mailers/concerns/ics_multipart_attached.rb

    def self.from_payload(payload)
      cal = Icalendar::Calendar.new

      cal.add_timezone Time.zone_default.tzinfo.ical_timezone payload[:starts_at]
      cal.prodid = BRAND
      cal.event { |event| populate_event(event, payload) }
      cal.ip_method = if payload[:action] == :destroy
                        "CANCEL"
                      elsif payload[:attendees].present?
                        "REQUEST" # REQUEST is only allowed if ATTENDEEs are present.
                      else
                        "PUBLISH"
                      end
      cal
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
      if payload[:attendees].present?
        payload[:attendees].each { |attendee| event.append_attendee("mailto:#{attendee}") }
      end
      event.summary = payload[:summary]
      event.location = payload[:address]
      event.rrule = payload[:recurrence]
      event.sequence = payload[:sequence]
      event.description = payload[:description]
      event.organizer = "mailto:secretariat-auto@rdv-solidarites.fr"
    end
  end
end
