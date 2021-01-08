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

    cal.event do |e|
      e.dtstart     = Icalendar::Values::DateTime.new(rdv.starts_at, "tzid" => tzid)
      e.dtend       = Icalendar::Values::DateTime.new(rdv.ends_at, "tzid" => tzid)
      e.summary     = "RDV #{rdv_title_for_user(rdv, user)}"
      e.description = description
      e.location    = rdv.address unless rdv.motif.phone?
      e.uid         = rdv.uuid
      e.sequence    = rdv.sequence
      e.ip_class    = "PRIVATE"
      e.attendee    = "mailto:#{user.email}"
      e.organizer   = "mailto:contact@rdv-solidarites.fr"
    end

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
end
