module AntsApi
  class Appointment
    class ApiRequestError < StandardError; end

    CONSUMED = "consumed".freeze

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

    def syncable?
      self.class.status(application_id: @application_id)["status"] != CONSUMED
    end

    private

    def request(&block)
      self.class.request(&block)
    end

    class << self
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

        response.body.empty? ? {} : JSON.parse(response.body)
      end
    end
  end
end
