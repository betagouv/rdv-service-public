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

    def to_create_params
      {
        application_id: application_id,
        meeting_point: meeting_point,
        appointment_date: appointment_date.strftime("%Y-%m-%d %H:%M:%S"),
      }
    end

    def to_delete_params
      to_create_params.merge(management_url: management_url)
    end

    def ==(other)
      to_delete_params == other.to_delete_params
    end
  end

  def self.create_appointment(appointment)
    Typhoeus.post(
      "#{ENV['ANTS_RDV_API_URL']}/appointments",
      params: appointment.to_create_params,
      headers: headers
    )
  end

  def self.delete_appointment(appointment)
    Typhoeus.delete(
      "#{ENV['ANTS_RDV_API_URL']}/appointments",
      params: appointment.to_delete_params,
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
    response_body.dig(ants_pre_demande_number, "appointments").map do |appointment|
      AntsApi::Appointment.new(
        application_id: ants_pre_demande_number,
        meeting_point: appointment["meeting_point"],
        management_url: appointment["management_url"],
        appointment_date: Time.zone.parse(appointment["appointment_date"])
      )
    end
  end

  def self.headers
    {
      "Accept" => "application/json",
      "x-rdv-opt-auth-token" => ENV["ANTS_RDV_OPT_AUTH_TOKEN"],
    }
  end
end
