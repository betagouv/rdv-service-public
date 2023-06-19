# frozen_string_literal: true

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

  def self.headers
    {
      "Accept" => "application/json",
      "x-rdv-opt-auth-token" => ENV["ANTS_RDV_OPT_AUTH_TOKEN"],
    }
  end
end
