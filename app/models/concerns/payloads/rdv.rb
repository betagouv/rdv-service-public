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

      payload[:action] = action if action.present?

      payload
    end
  end
end
