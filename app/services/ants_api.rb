# frozen_string_literal: true

class AntsApi
  class << self
    def pre_demande_number_valid?(pre_demande_number)
      api_response = request_pre_demande_number_status(pre_demande_number)
      api_response["status"] == "validated" && api_response["appointments"].empty?
    end

    def create_appointment(application_id:, meeting_point:, appointment_date:, management_url:)
      Typhoeus.post(
        "#{ENV['ANTS_RDV_API_URL']}/appointments",
        params: {
          application_id: application_id,
          meeting_point: meeting_point,
          appointment_date: appointment_date,
          management_url: management_url
        },
        headers: headers
      )
    end

    def delete_appointment(application_id:, meeting_point:, appointment_date:)
      Typhoeus.delete(
        "#{ENV['ANTS_RDV_API_URL']}/appointments",
        params: {
          application_id: application_id,
          meeting_point: meeting_point,
          appointment_date: appointment_date,
        },
        headers: headers,
      )
    end

    private

    def request_pre_demande_number_status(pre_demande_number)
      response_body = Typhoeus.get(
        "#{ENV['ANTS_RDV_API_URL']}/status?application_ids=#{pre_demande_number}",
        headers: headers
      ).response_body

      JSON.parse(response_body).fetch(pre_demande_number, {})
    end

    def headers
      {
        "Accept" => "application/json",
        "x-rdv-opt-auth-token" => ENV["ANTS_RDV_OPT_AUTH_TOKEN"],
      }
    end

    def request_params(rdv:, user:)
      {
        application_id: user.ants_pre_demande_number,
        meeting_point: rdv.lieu.name,
        appointment_date: rdv.starts_at.strftime("%Y-%m-%d %H:%M:%S")
      }
    end
  end
end
