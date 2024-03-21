# Doc de l'API :
# https://api-coordination.rendezvouspasseport.ants.gouv.fr/docs

# Code source du système "Optimisation des rendez-vous en mairies" de l'ANTS :
# https://gitlab.com/france-titres/rendez-vous-mairie/optimisation-rendez-vous-mairie

module AntsApi
  class Appointment < Base
    attr_reader :application_id, :meeting_point, :appointment_date, :management_url

    def initialize(application_id:, meeting_point:, appointment_date:, management_url:)
      @application_id = application_id
      @meeting_point = meeting_point
      @appointment_date = appointment_date
      @management_url = management_url
    end

    def to_request_params
      {
        application_id: @application_id,
        meeting_point: @meeting_point,
        appointment_date: @appointment_date,
        management_url: @management_url,
      }
    end

    def create
      response = Typhoeus.post(
        "#{ENV['ANTS_RDV_API_URL']}/appointments",
        params: {
          application_id: @application_id,
          meeting_point: @meeting_point,
          appointment_date: @appointment_date,
          management_url: @management_url,
        },
        headers: self.class.headers
      )

      unless response.success?
        raise(ApiRequestError, "code:#{response.response_code}, body:#{response.response_body}")
      end

      JSON.parse(response.body)
    end

    def delete
      response = Typhoeus.delete(
        "#{ENV['ANTS_RDV_API_URL']}/appointments",
        params: {
          application_id: @application_id,
          meeting_point: @meeting_point,
          appointment_date: @appointment_date,
        },
        headers: self.class.headers
      )

      unless response.success?
        raise(ApiRequestError, "code:#{response.response_code}, body:#{response.response_body}")
      end

      JSON.parse(response.body)
    end

    class << self
      def remove_appointment_from_application(application_id:)
        pre_demande_status = AntsApplication.find(application_id)
        if pre_demande_status.status == [AntsApplication::VALIDATED]
          ____
        end
      end

      def find_by(application_id:, management_url:)
        pre_demande_status = AntsApplication.find(application_id)
        appointment_data = load_appointments(application_id).find do |appointment|
          appointment["management_url"] == management_url
        end
        Appointment.new(application_id: application_id, **appointment_data.symbolize_keys) if appointment_data
      end

      def first(application_id:, timeout: nil)
        pre_demande_status = AntsApplication.find(application_id)
        appointment_data = load_appointments(application_id, timeout: timeout).first
        Appointment.new(application_id: application_id, **appointment_data.symbolize_keys) if appointment_data
      end
    end
  end
end
