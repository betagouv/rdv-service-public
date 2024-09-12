module IcsPayloads
  module PlageOuverture
    def payload(action = nil)
      payload = {
        name: "plage-ouverture-#{title.parameterize}-#{starts_at.to_s.parameterize}.ics",
        starts_at: starts_at,
        ends_at: first_occurrence_ends_at,
        ical_uid: ical_uid,
        summary: "#{IcalFormatters::Ics::ICS_UID_SUFFIX} #{title}",
        rrule: IcalFormatters::Rrule.from_recurrence(recurrence),
        domain: domain,
      }

      payload[:action] = action if action.present?

      payload
    end
  end
end
