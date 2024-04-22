module AntsApi
  class Appointment
    class ApiRequestError < StandardError; end

    attr_reader :application_id, :meeting_point, :appointment_date, :management_url

    VALIDATED = "validated".freeze

    CONSUMED = "consumed".freeze
    DECLARED = "declared".freeze
    UNKNOWN = "unknown".freeze
    EXPIRED = "expired".freeze

    # https://api-coordination.rendezvouspasseport.ants.gouv.fr/docs#/Application%20Ids%20-%20%C3%A9diteurs/get_status_api_status_get
    ERROR_STATUSES = {
      CONSUMED => "correspond à un dossier déjà instruit",
      DECLARED => "n'est pas officiellement reconnu par l'ANTS",
      UNKNOWN => "n'est pas reconnu par l'ANTS",
      EXPIRED => "correspond à un dossier expiré",
    }.freeze

    # Voir la liste des attributs sur la doc API :
    # https://api-coordination.rendezvouspasseport.ants.gouv.fr/docs
    def initialize(application_id:, appointment_data:)
      @application_id = application_id

      appointment_data = appointment_data.with_indifferent_access

      # required attrs
      @appointment_date = appointment_data.fetch(:appointment_date)
      @management_url = appointment_data.fetch(:management_url)
      @meeting_point = appointment_data.fetch(:meeting_point)

      # optional attrs
      @meeting_point_id = appointment_data[:meeting_point_id]
    end

    def to_request_params
      {
        application_id: @application_id,
        meeting_point_id: @meeting_point_id,
        meeting_point: @meeting_point,
        appointment_date: @appointment_date,
        management_url: @management_url,
      }
    end

    def create
      request do
        Typhoeus.post(
          "#{ENV['ANTS_RDV_API_URL']}/appointments",
          params: to_request_params,
          headers: self.class.headers
        )
      end
    end

    def delete
      request do
        Typhoeus.delete(
          "#{ENV['ANTS_RDV_API_URL']}/appointments",
          params: to_request_params.except(:management_url),
          headers: self.class.headers
        )
      end
    end

    private

    def request(&block)
      self.class.request(&block)
    end

    class << self
      def find_by(application_id:, management_url:)
        appointment_data = load_appointments(application_id).find do |appointment|
          appointment["management_url"] == management_url
        end
        Appointment.new(application_id: application_id, appointment_data: appointment_data) if appointment_data
      end

      def first(application_id:, timeout: nil)
        appointment_data = load_appointments(application_id, timeout: timeout).first
        Appointment.new(application_id: application_id, appointment_data: appointment_data) if appointment_data
      end

      def status(application_id:, timeout: nil)
        response_body = request do
          Typhoeus.get(
            "#{ENV['ANTS_RDV_API_URL']}/status",
            params: { application_ids: application_id },
            headers: headers,
            timeout: timeout
          )
        end

        response_body.fetch(application_id)
      end

      def headers
        {
          "Accept" => "application/json",
          "x-rdv-opt-auth-token" => ENV["ANTS_RDV_OPT_AUTH_TOKEN"],
        }
      end

      def request(&block)
        response = block.call
        unless response.success?
          raise(ApiRequestError, "code:#{response.response_code}, body:#{response.response_body}")
        end

        JSON.parse(response.body)
      end

      private

      def load_appointments(application_id, timeout: nil)
        status(application_id: application_id, timeout: timeout).fetch("appointments")
      end
    end
  end
end
