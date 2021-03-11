class Admin::Ics::Rdv
  def self.payload(rdv, user)
    {
      name: "rdv-#{rdv.uuid}-#{rdv.starts_at.to_s.parameterize}.ics",
      starts_at: rdv.starts_at,
      ends_at: rdv.ends_at,
      sequence: rdv.sequence,
      description: description(rdv),
      address: rdv.motif.phone? ? nil : rdv.address,
      ical_uid: rdv.uuid,
      summary: "RDV #{rdv_title_for_user(rdv, user)}",
      user_email: user.email
    }
  end

  def self.description(rdv)
    description = ""
    description += "RDV Téléphonique " if rdv.motif.phone?
    description += "Infos et annulation: #{Rails.application.routes.url_helpers.rdvs_shorten_url(host: ENV['HOST'])}"
    description
  end

  def self.rdv_title_for_user(rdv, user)
    "#{user.full_name} <> #{rdv.motif&.name}"
  end

  def self.to_ical(payload)
    cal = Icalendar::Calendar.new

    tz = TZInfo::Timezone.get Admin::Ics::TZID
    timezone = tz.ical_timezone payload[:starts_at]
    cal.add_timezone timezone
    cal.prodid = BRAND
    cal.event { populate_event(_1, payload) }
    cal.ip_method = "REQUEST"
    cal.to_ical
  end

  def self.populate_event(event, payload)
    event.uid = payload[:ical_uid]
    event.dtstart = Icalendar::Values::DateTime.new(payload[:starts_at], "tzid" => Admin::Ics::TZID)
    event.dtend = Icalendar::Values::DateTime.new(payload[:ends_at], "tzid" => Admin::Ics::TZID)
    event.summary = payload[:summary]
    event.location = payload[:address]
    event.ip_class = "PUBLIC"
    event.rrule = payload[:recurrence]
    event.sequence = payload[:sequence]
    event.description = payload[:description]
    event.attendee = "mailto:#{payload[:user_email]}"
    event.ip_class = "PRIVATE"
    event.organizer = "mailto:contact@rdv-solidarites.fr"
  end
end
