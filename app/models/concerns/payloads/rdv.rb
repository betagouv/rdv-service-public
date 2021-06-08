# frozen_string_literal: true

module Payloads
  module Rdv
    def payload(action = nil, user = users.first)
      payload = {
        name: "rdv-#{uuid}-#{starts_at.to_s.parameterize}.ics",
        user_email: user.email,
        starts_at: starts_at,
        ends_at: ends_at,
        ical_uid: uuid,
        summary: "RDV #{user.full_name} <> #{motif&.name}",
        address: motif.phone? ? nil : address,
        sequence: sequence
      }

      description = ""
      description += "RDV Téléphonique " if motif.phone?
      description += "Infos et annulation: #{Rails.application.routes.url_helpers.rdvs_shorten_url(host: ENV['HOST'])}"
      payload[:description] = description

      payload.merge!(
        {
          home?: home?,
          phone?: phone?,
          reservable_online?: reservable_online?,
          users_full_names: users.map(&:full_name).sort.to_sentence,
          motif_name: motif.name,
          motif_instruction: motif.instruction_for_rdv,
          service_name: motif.service.name,
          duration_in_min: duration_in_min,
          address_complete: address_complete,
          phone_number: phone_number,
          phone_number_formatter: phone_number_formatted,
          organisation_id: organisation.id,
          service_id: motif.service.id,
          organisation_name: organisation.name,
          organisation_departement_number: organisation.departement_number,
          motif_name_with_location_type: motif.name_with_location_type
        }
      )

      payload[:action] = action if action.present?

      payload
    end
  end
end
