class Rdv::Ics
  include ActiveModel::Model
  include Rails.application.routes.url_helpers

  attr_accessor :rdv
  validates :rdv, presence: true

  def to_ical_for(user)
    require 'icalendar'
    require 'icalendar/tzinfo'

    cal = Icalendar::Calendar.new

    tzid = "Europe/Paris"
    tz = TZInfo::Timezone.get tzid
    timezone = tz.ical_timezone rdv.starts_at
    cal.add_timezone timezone

    cal.event do |e|
      e.dtstart     = Icalendar::Values::DateTime.new(rdv.starts_at, 'tzid' => tzid)
      e.dtend       = Icalendar::Values::DateTime.new(rdv.ends_at, 'tzid' => tzid)
      e.summary     = "RDV #{rdv.name}"
      e.description = description
      e.location    = rdv.location unless rdv.motif.by_phone?
      e.uid         = rdv.uuid
      e.sequence    = rdv.sequence
      e.ip_class    = "PRIVATE"
      e.attendee    = user.email
    end

    cal.ip_method = "REQUEST"
    cal.to_ical
  end

  def description
    d = ""
    d += "RDV Téléphonique " if @rdv.motif.by_phone
    d += "Infos et annulation: #{rdvs_shorten_url(host: "https://#{ENV["HOST"]}")}"
    d
  end

  def name
    "rdv-#{rdv.name.parameterize}-#{rdv.starts_at.to_s.parameterize}.ics"
  end
end
