class Rdv::Ics
  include ActiveModel::Model
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
      e.description = ""
      e.location    = rdv.location unless rdv.motif.by_phone?
      e.uid         = rdv.uuid
      e.sequence    = rdv.sequence
      e.ip_class    = "PRIVATE"
      e.organizer   = "noreply@rdv-solidarites.fr"
      e.attendee    = user.email
    end

    cal.ip_method = "REQUEST"
    cal.to_ical
  end

  def name
    "rdv-#{rdv.name.parameterize}-#{rdv.starts_at.to_s.parameterize}.ics"
  end
end
