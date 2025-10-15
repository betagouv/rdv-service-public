require "icalendar/tzinfo"

module IcalFormatters
  module Ics
    # Cette constante est ajoutée aux UIDs des événements ICS afin
    # d'empêcher la collision (certes improbable) avec des événements
    # d'autres plateformes. Il est important de ne pas modifier cette
    # constante car cel ferait changer les UIDs (et un ID ne doit pas changer).
    ICS_UID_SUFFIX = "RDV Solidarités".freeze

    # Specs
    # iCalendar: https://datatracker.ietf.org/doc/html/rfc5545#section-3.6.1
    #   * See section 3.6.1 for VEVENT
    # iTIP: https://datatracker.ietf.org/doc/html/rfc2446#section-3.2
    #   * See section 3.2 for the semantics of the METHOD
    #
    # See also mailers/concerns/ics_multipart_attached.rb

    def self.from_payload(payload)
      # Pour la gestion des fuseaux horaires, voir : https://github.com/betagouv/rdv-service-public/pull/5719#discussion_r2431975425
      tzid = payload[:tzid] || Time.zone_default.tzinfo.identifier

      cal = Icalendar::Calendar.new

      tz = TZInfo::Timezone.get(tzid)
      cal.add_timezone(tz.ical_timezone(payload[:starts_at]))
      cal.prodid = ICS_UID_SUFFIX
      cal.event { |event| populate_event(event, payload, tzid) }
      cal.ip_method = if payload[:action] == :destroy
                        "CANCEL"
                      elsif payload[:attendees].present?
                        "REQUEST" # REQUEST is only allowed if ATTENDEEs are present.
                      else
                        "PUBLISH"
                      end
      cal
    end

    # rubocop:disable Metrics/PerceivedComplexity
    def self.populate_event(event, payload, tzid)
      event.uid = payload[:ical_uid]
      event.status = if payload[:action].present? && payload[:action] == :destroy
                       "CANCELLED"
                     elsif payload[:status]
                       payload[:status]
                     else
                       "CONFIRMED"
                     end
      if payload[:starts_at].present?
        dtstart = Icalendar::Values::DateTime.new(payload[:starts_at],
                                                  "tzid" => tzid)
        event.dtstart = dtstart
      end
      if payload[:ends_at].present?
        dtend = Icalendar::Values::DateTime.new(payload[:ends_at],
                                                "tzid" => tzid)
        event.dtend = dtend
      end
      if payload[:attendees].present?
        payload[:attendees].each { |attendee| event.append_attendee("PARTSTAT=ACCEPTED;mailto:#{attendee}") }
      end
      event.summary = payload[:summary]
      event.location = payload[:location]
      event.rrule = payload[:rrule]
      event.sequence = 0 # not sure if this is necessary, but not worth investigating right now
      event.description = payload[:description]
      event.organizer = "mailto:#{payload[:domain].secretariat_email}"
      event.categories = ["RDV Service Public"] # Cette catégorie permet de filtrer tous les événements que nous créons.
    end
    # rubocop:enable Metrics/PerceivedComplexity
  end
end
