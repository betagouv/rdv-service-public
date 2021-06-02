# frozen_string_literal: true

module Payloads
  module Absence
    def payload(action = nil)
      payload = {
        name: "absence-#{title.parameterize}-#{starts_at.to_s.parameterize}.ics",
        agent_email: agent.email,
        starts_at: starts_at,
        ends_at: first_occurrence_ends_at,
        ical_uid: ical_uid,
        summary: "#{BRAND} #{title}",
        title: title,
        recurrence: rrule
      }

      payload[:action] = action if action.present?

      payload
    end
  end
end
