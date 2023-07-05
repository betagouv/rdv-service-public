# frozen_string_literal: true

# Wrapper autour de l'API de l'ANTS pour la gestion des doublons
class AntsApiAppointment
  def self.list(ants_pre_demande_number)
    response = Typhoeus.get(
      "#{ENV['ANTS_RDV_API_URL']}/status",
      params: { application_ids: ants_pre_demande_number },
      headers: headers
    )
    response_body = response.body.empty? ? {} : JSON.parse(response.body)
    response_body.dig(ants_pre_demande_number, "appointments").map do |appointment|
      new(
        application_id: ants_pre_demande_number,
        meeting_point: appointment["meeting_point"],
        management_url: appointment["management_url"],
        appointment_date: Time.zone.parse(appointment["appointment_date"])
      )
    end
  end

  attr_reader :application_id, :meeting_point, :appointment_date, :management_url

  def initialize(application_id:, meeting_point:, appointment_date:, management_url:)
    @application_id = application_id
    @meeting_point = meeting_point
    @appointment_date = appointment_date
    @management_url = management_url
  end

  def create!
    Typhoeus.post(
      "#{ENV['ANTS_RDV_API_URL']}/appointments",
      params: create_params,
      headers: self.class.headers
    )
  end

  def delete!
    Typhoeus.delete(
      "#{ENV['ANTS_RDV_API_URL']}/appointments",
      params: delete_params,
      headers: self.class.headers
    )
  end

  def ==(other)
    create_params == other.create_params
  end

  def self.headers
    {
      "Accept" => "application/json",
      "x-rdv-opt-auth-token" => ENV["ANTS_RDV_OPT_AUTH_TOKEN"],
    }
  end

  private

  def create_params
    delete_params.merge(management_url: management_url)
  end

  def delete_params
    {
      application_id: application_id,
      meeting_point: meeting_point,
      appointment_date: appointment_date.strftime("%Y-%m-%d %H:%M:%S"),
    }
  end
end
