class Rdv::Ics
  include ActiveModel::Model
  include Rails.application.routes.url_helpers
  include RdvsHelper

  attr_accessor :rdv

  validates :rdv, presence: true

  def to_ical_for(user)
    require "icalendar"
    require "icalendar/tzinfo"

    cal = Icalendar::Calendar.new

    tzid = "Europe/Paris"
    tz = TZInfo::Timezone.get tzid
    timezone = tz.ical_timezone rdv.starts_at
    cal.add_timezone timezone
    cal.prodid = BRAND
    cal.event { populate_event(_1, user) }
    cal.ip_method = "REQUEST"
    cal.to_ical
  end

  def description
    d = ""
    d += "RDV Téléphonique " if @rdv.motif.phone?
    d += "Infos et annulation: #{rdvs_shorten_url(host: ENV["HOST"])}"
    d
  end

  def name
    "rdv-#{rdv.uuid}-#{rdv.starts_at.to_s.parameterize}.ics"
  end

  private

  def populate_event(event, user)
    event.dtstart     = Icalendar::Values::DateTime.new(rdv.starts_at, "tzid" => tzid)
    event.dtend       = Icalendar::Values::DateTime.new(rdv.ends_at, "tzid" => tzid)
    event.summary     = "RDV #{rdv_title_for_user(rdv, user)}"
    event.description = description
    event.location    = rdv.address unless rdv.motif.phone?
    event.uid         = rdv.uuid
    event.sequence    = rdv.sequence
    event.ip_class    = "PRIVATE"
    event.attendee    = "mailto:#{user.email}"
    event.organizer   = "mailto:contact@rdv-solidarites.fr"
  end
end
