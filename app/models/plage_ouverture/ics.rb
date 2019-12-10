class PlageOuverture::Ics
  include ActiveModel::Model
  attr_accessor :plage_ouverture
  validates :plage_ouverture, presence: true

  def to_ical
    require 'icalendar'
    require 'icalendar/tzinfo'

    cal = Icalendar::Calendar.new

    tzid = "Europe/Paris"
    tz = TZInfo::Timezone.get tzid
    timezone = tz.ical_timezone plage_ouverture.starts_at
    cal.add_timezone timezone

    cal.event do |e|
      e.dtstart     = Icalendar::Values::DateTime.new(plage_ouverture.starts_at, 'tzid' => tzid)
      e.dtend       = Icalendar::Values::DateTime.new(plage_ouverture.ends_at, 'tzid' => tzid)
      e.summary     = "#{BRAND} #{plage_ouverture.title}"
      e.description = ""
      e.location    = plage_ouverture.lieu.address
      e.ip_class    = "PRIVATE"
      e.organizer   = "noreply@rdv-solidarites.fr"
      e.attendee    = plage_ouverture.agent.email
    end

    cal.ip_method = "REQUEST"
    cal.to_ical
  end

  def name
    "plage-ouverture-#{plage_ouverture.title.parameterize}-#{plage_ouverture.starts_at.to_s.parameterize}.ics"
  end
end
