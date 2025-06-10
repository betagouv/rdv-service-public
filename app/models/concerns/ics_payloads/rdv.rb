module IcsPayloads
  module Rdv
    def payload(action = nil, recipient = users.first)
      payload = {
        name: "rdv-#{uuid}-#{starts_at.to_s.parameterize}.ics",
        starts_at: starts_at,
        ends_at: ends_at,
        ical_uid: uuid,
        summary: "RDV #{motif&.name}",
        address: motif.phone? ? nil : address,
        domain: domain,
      }

      payload[:description] = ics_description(recipient)

      # NOTE: for agents, we include all agents as the attendees. This also changes the method from PUBLISH to REQUEST.
      if recipient.is_a? Agent
        payload[:attendees] = agents.pluck(:email)
      end

      payload[:name] = name if name.present?
      payload[:action] = action if action.present?

      payload
    end

    private

    def ics_description(recipient)
      description = ""
      description += "RDV Téléphonique " if motif.phone?
      description += case recipient
                     when User
                       "Infos et annulation: #{Rails.application.routes.url_helpers.rdvs_short_url(host: domain.host_name)}"
                     when Agent
                       "Voir sur #{domain.name}: #{Rails.application.routes.url_helpers.admin_organisation_rdv_url(organisation_id, self, host: domain.host_name)}"
                     end

      if recipient.is_a?(Agent) && rdv_plan&.dossier_url
        description += "\nVoir sur #{rdv_plan.oauth_application&.name}: #{rdv_plan.dossier_url}"
      end

      description
    end
  end
end
