module IcsPayloads
  module PlageOuverture
    def payload(action = nil)
      payload = {
        name: "plage-ouverture-#{title.presence&.parameterize || id}-#{starts_at.to_s.parameterize}.ics",
        starts_at: starts_at,
        ends_at: first_occurrence_ends_at,
        ical_uid: ical_uid,
        summary: title_with_default,
        description: "Voir sur #{domain.name} : #{Rails.application.routes.url_helpers.admin_organisation_planning_plage_ouverture_url(organisation, id, host: domain.host_name)}",
        location: lieu_address,
        rrule: IcalFormatters::Rrule.from_recurrence(recurrence),
        domain: domain,
      }

      payload[:action] = action if action.present?

      payload
    end
  end
end
