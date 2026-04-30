module IcsPayloads
  module Rdv
    def payload(action: nil, recipient: users.first, sensitive_data: false)
      payload = {
        attachement_filename: "rdv-#{motif&.name&.parameterize}-#{starts_at.strftime('%Y-%m-%d-%Hh%M')}.ics",
        starts_at: starts_at,
        ends_at: ends_at,
        ical_uid: uuid,
        summary: ics_summary(recipient: recipient, sensitive_data: sensitive_data),
        location: ics_location(sensitive_data: sensitive_data),
        domain: domain,
        status: ics_status,
        tzid: organisation&.time_zone,
      }

      payload[:description] = ics_description(recipient, sensitive_data: sensitive_data)

      # NOTE: for agents, we include all agents as the attendees. This also changes the method from PUBLISH to REQUEST.
      if recipient.is_a? Agent
        payload[:attendees] = agents.pluck(:email)
      end

      payload[:action] = action if action.present?

      payload
    end

    def ics_location(sensitive_data: false)
      case motif.location_type.to_sym
      when :phone then users.first&.phone_number_formatted if sensitive_data
      when :visio then visio_url
      when :home then users.first&.address if sensitive_data
      else address
      end
    end

    def ics_description(recipient, sensitive_data: false)
      description = ics_description_prefix
      description += ics_description_link(recipient)
      description += ics_description_dossier_link(recipient)
      description += ics_description_context(recipient, sensitive_data)
      description
    end

    private

    def ics_description_prefix
      description = ""
      description += "RDV Téléphonique " if motif.phone?
      description += "RDV par visioconférence " if motif.visio?
      description
    end

    def ics_description_link(recipient)
      case recipient
      when User
        "Infos et annulation: #{Rails.application.routes.url_helpers.rdvs_short_url(host: domain.host_name)}"
      when Agent
        "Voir sur #{domain.name}: #{Rails.application.routes.url_helpers.admin_organisation_rdv_url(organisation_id, self, host: domain.host_name)}"
      else
        ""
      end
    end

    def ics_description_dossier_link(recipient)
      return "" unless recipient.is_a?(Agent) && rdv_plan&.dossier_url

      "\nVoir sur #{rdv_plan.oauth_application&.name}: #{rdv_plan.dossier_url}"
    end

    def ics_description_context(recipient, sensitive_data)
      return "" unless sensitive_data && recipient.is_a?(Agent) && context.present?

      "\nContexte : #{context}"
    end

    def ics_summary(recipient:, sensitive_data:)
      if motif.collectif?
        "RDV collectif - #{motif&.name}"
      elsif sensitive_data
        "RDV avec #{recipient.full_name} - #{motif&.name}"
      else
        "RDV #{motif&.name}"
      end
    end

    def ics_status
      if cancelled?
        "CANCELLED"
      else
        "CONFIRMED"
      end
    end
  end
end
