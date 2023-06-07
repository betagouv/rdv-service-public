# frozen_string_literal: true

module Payloads
  module Absence
    def payload(action = nil)
      payload = {
        name: "absence-#{title.parameterize}-#{starts_at.to_s.parameterize}.ics",
        starts_at: starts_at,
        ends_at: first_occurrence_ends_at,
        ical_uid: ical_uid,
        summary: "#{IcalHelpers::ICS_UID_SUFFIX} #{title}",
        recurrence: rrule,
        domain: domain,
      }

      payload[:action] = action if action.present?

      payload
    end
  end
end
