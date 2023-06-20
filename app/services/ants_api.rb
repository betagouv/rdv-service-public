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

  def self.create_appointment(appointment)
    Typhoeus.post(
      "#{ENV['ANTS_RDV_API_URL']}/appointments",
      params: appointment.to_request_params,
      headers: headers
    )
  end

  def self.delete_appointment(appointment)
    Typhoeus.delete(
      "#{ENV['ANTS_RDV_API_URL']}/appointments",
      params: appointment.to_request_params(action: :delete),
      headers: headers
    )
  end

  def self.find_appointment(application_id:, management_url:)
    response = Typhoeus.get(
      "#{ENV['ANTS_RDV_API_URL']}/status",
      params: { application_ids: application_id },
      headers: headers
    )
    response_body = response.body.empty? ? {} : JSON.parse(response.body)
    appointments = response_body.fetch(application_id, {})["appointments"]
    return nil if appointments.blank?

    appointment_data = appointments.find do |appointment|
      appointment["management_url"] == management_url
    end

    Appointment.new(
      application_id: application_id,
      management_url: appointment_data["management_url"],
      meeting_point: appointment_data["meeting_point"],
      appointment_date: appointment_data["appointment_date"]
    )
  end

  def self.headers
    {
      "Accept" => "application/json",
      "x-rdv-opt-auth-token" => ENV["ANTS_RDV_OPT_AUTH_TOKEN"],
    }
  end
end
