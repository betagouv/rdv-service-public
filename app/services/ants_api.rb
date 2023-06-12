# frozen_string_literal: true

class AntsApi
  class << self
    include Rails.application.routes.url_helpers

    def pre_demande_number_valid?(pre_demande_number)
      api_response = request_pre_demande_number_status(pre_demande_number)
      api_response.fetch(pre_demande_number, {})["status"] == "validated"
    end

    def create_appointment(rdv:, user:)
      Typhoeus.post(
        "#{ENV['ANTS_RDV_API_URL']}/api/appointments",
        params: {
          application_id: user.ants_pre_demande_number,
          management_url: rdvs_short_url(rdv, host: rdv.organisation.domain.host_name),
          meeting_point: rdv.lieu.name,
          appointment_date: rdv.starts_at.strftime("%Y-%m-%d %H:%M:%S"),
        },
        **headers
      )
    end

    private

    def request_pre_demande_number_status(pre_demande_number)
      response = Typhoeus.get(
        "#{ENV['ANTS_RDV_API_URL']}/api/status?application_ids=#{pre_demande_number}",
        **headers
      )

      JSON.parse(response.response_body)
    end

    def headers
      {
        headers: {
          "Accept" => "application/json",
          "x-rdv-opt-auth-token" => ENV["ANTS_RDV_OPT_AUTH_TOKEN"],
        },
      }
    end
  end
end
