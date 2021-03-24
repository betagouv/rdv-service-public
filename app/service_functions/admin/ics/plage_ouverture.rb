class Admin::Ics::PlageOuverture
  include Admin::Ics

  def self.create_payload(plage_ouverture)
    payload(plage_ouverture).merge(action: :create)
  end

  def self.update_payload(plage_ouverture)
    payload(plage_ouverture).merge(action: :update)
  end

  def self.destroy_payload(plage_ouverture)
    payload(plage_ouverture).merge(action: :destroy)
  end

  def self.payload(plage_ouverture)
    {
      name: "plage-ouverture-#{plage_ouverture.title.parameterize}-#{plage_ouverture.starts_at.to_s.parameterize}.ics",
      agent_email: plage_ouverture.agent.email,
      starts_at: plage_ouverture.starts_at,
      recurrence: rrule(plage_ouverture),
      ical_uid: plage_ouverture.ical_uid,
      title: plage_ouverture.title,
      first_occurrence_ends_at: plage_ouverture.first_occurrence_ends_at,
      address: plage_ouverture.lieu.address
    }
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
    event.dtstart = Icalendar::Values::DateTime.new(payload[:starts_at], "tzid" => TZID)
    event.dtend = Icalendar::Values::DateTime.new(payload[:first_occurrence_ends_at], "tzid" => TZID)
    event.summary = "#{BRAND} #{payload[:title]}"
    event.location = payload[:address]
    event.ip_class = "PUBLIC"
    event.status = Admin::Ics.status_from_action(payload[:action])
    event.attendee = "mailto:#{payload[:agent_email]}"
    event.organizer = "mailto:secretariat-auto@rdv-solidarites.fr"
  end

  def self.rrule(plage_ouverture)
    return unless plage_ouverture.recurrence.present?

    recurrence_hash = plage_ouverture.recurrence.to_hash

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

  def self.by_month_day(day)
    "#{day.values.first.first}#{Date::DAYNAMES[day.keys.first][0, 2].upcase}"
  end

  def self.interval_from_hash(recurrence_hash)
    "INTERVAL=#{recurrence_hash[:interval]};" if recurrence_hash[:interval]
  end

  def self.until_from_hash(recurrence_hash)
    "UNTIL=#{Icalendar::Values::DateTime.new(recurrence_hash[:until], 'tzid' => TZID).value_ical};" if recurrence_hash[:until]
  end

  def self.by_week_day(on)
    if on.is_a?(String)
      on[0, 2].upcase
    else
      on.map { |d| d[0, 2].upcase }.join(",")
    end
  end
end
