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
  end

  def self.create_appointment(appointment)
    Typhoeus.post(
      "#{ENV['ANTS_RDV_API_URL']}/appointments",
      params: {
        application_id: appointment.application_id,
        meeting_point: appointment.meeting_point,
        appointment_date: appointment.appointment_date,
        management_url: appointment.management_url,
      },
      headers: headers
    )
  end

  def self.delete_appointment(appointment)
    Typhoeus.delete(
      "#{ENV['ANTS_RDV_API_URL']}/appointments",
      params: {
        application_id: appointment.application_id,
        meeting_point: appointment.meeting_point,
        appointment_date: appointment.appointment_date,
      },
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
