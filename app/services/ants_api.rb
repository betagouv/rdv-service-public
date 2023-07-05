# frozen_string_literal: true

# Wrapper autour de l'API de l'ANTS pour la gestion des doublons
module AntsApi
  class Appointment
    attr_reader :application_id, :meeting_point, :appointment_date, :management_url

    def initialize(application_id:, meeting_point:, appointment_date:, management_url:)
      @application_id = application_id
      @meeting_point = meeting_point
      @appointment_date = appointment_date
      @management_url = management_url
    end

    def to_request_params(action: :create)
      params = {
        application_id: application_id,
        meeting_point: meeting_point,
        appointment_date: appointment_date,
      }

      action == :delete ? params : params.merge(management_url: management_url)
    end
  end

  def self.create_appointment(ants_pre_demande_number, appointment_hash)
    Typhoeus.post(
      "#{ENV['ANTS_RDV_API_URL']}/appointments",
      params: appointment_hash.merge(application_id: ants_pre_demande_number),
      headers: headers
    )
  end

  def self.delete_appointment(_ants_pre_demande_number, appointment_hash)
    Typhoeus.delete(
      "#{ENV['ANTS_RDV_API_URL']}/appointments",
      params: appointment_hash.merge(application_id: ants_pre_demande_number, action: :delete),
      headers: headers
    )
  end

  def self.list_appointments(ants_pre_demande_number)
    response = Typhoeus.get(
      "#{ENV['ANTS_RDV_API_URL']}/status",
      params: { application_ids: ants_pre_demande_number },
      headers: headers
    )
    response_body = response.body.empty? ? {} : JSON.parse(response.body)
    response_body.dig(ants_pre_demande_number, "appointments")
  end

  def self.headers
    {
      "Accept" => "application/json",
      "x-rdv-opt-auth-token" => ENV["ANTS_RDV_OPT_AUTH_TOKEN"],
    }
  end
end
