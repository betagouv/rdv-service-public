# frozen_string_literal: true

module Payloads
  module Rdv
    def payload(action = nil, recipient = users.first) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      payload = {
        name: "rdv-#{uuid}-#{starts_at.to_s.parameterize}.ics",
        starts_at: starts_at,
        ends_at: ends_at,
        ical_uid: uuid,
        summary: "RDV #{motif&.name}",
        address: motif.phone? ? nil : address,
        sequence: sequence
      }

      description = ""
      description += "RDV Téléphonique " if motif.phone?
      description += case recipient
                     when User
                       "Infos et annulation: #{Rails.application.routes.url_helpers.rdvs_shorten_url(host: ENV['HOST'])}"
                     when Agent
                       "Voir sur RDV-Solidarités: #{Rails.application.routes.url_helpers.admin_organisation_rdv_url(organisation_id, self, host: ENV['HOST'])}"
                     end
      payload[:description] = description

      # NOTE: for agents, we include all agents as the attendees. This also changes the method from PUBLISH to REQUEST.
      if recipient.is_a? Agent
        payload[:attendees] = agents.pluck(:email)
      end

      payload.merge!(
        {
          id: id,
          status: status,
          home?: home?,
          phone?: phone?,
          follow_up?: follow_up?,
          reservable_online?: reservable_online?,
          users_full_names: users.map(&:full_name).sort.to_sentence,
          agents_short_names: agents.map(&:short_name).sort.to_sentence,
          motif_name: motif.name,
          motif_instruction: motif.instruction_for_rdv,
          motif_service_name: motif.service.name,
          duration_in_min: duration_in_min,
          address_complete: address_complete,
          phone_number: phone_number,
          organisation_id: organisation.id,
          motif_service_id: motif.service.id,
          organisation_name: organisation.name,
          organisation_departement_number: organisation.departement_number,
          motif_name_with_location_type: motif.name_with_location_type,
          collectif?: collectif?
        }
      )

      payload[:action] = action if action.present?

      payload
    end
  end
end
