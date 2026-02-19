module IcsPayloads
  module Absence
    def payload(action = nil)
      payload = {
        attachement_filename: ics_attachment_filename,
        starts_at: starts_at,
        ends_at: first_occurrence_ends_at,
        ical_uid: ical_uid,
        summary: title,
        description: "Voir sur #{domain.name} : #{Rails.application.routes.url_helpers.edit_admin_organisation_planning_absence_url(agent.organisations.first, id, host: domain.host_name)}",
        rrule: IcalFormatters::Rrule.from_recurrence(recurrence),
        domain: domain,
      }

      payload[:action] = action if action.present?

      payload
    end
  end
end
