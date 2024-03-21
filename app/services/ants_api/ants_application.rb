module AntsApi
  class AntsApplication < Base
    STATUSES = [
      VALIDATED = "validated".freeze,
      CONSUMED = "consumed".freeze,
      DECLARED = "declared".freeze,
      UNKNOWN = "unknown".freeze,
      EXPIRED = "expired".freeze,
    ].freeze

    def self.find(application_id, timeout: nil)
      response = Typhoeus.get(
        "#{ENV['ANTS_RDV_API_URL']}/status",
        params: { application_ids: application_id },
        headers: headers,
        timeout: timeout
      )

      unless response.success?
        raise(ApiRequestError, "code:#{response.response_code}, body:#{response.response_body}")
      end

      new(application_id, JSON.parse(response.body))
    end

    def initialize(application_id, api_payload)
      @application_id = application_id
      @api_payload = api_payload
    end

    def allows_deletion?
      status.in?([VALIDATED, DECLARED])
    end

    def should_block_rdv_creation?
      status != VALIDATED
    end

    def status
      @api_payload["status"].presence or raise "unknown status #{@api_payload.inspect}"
    end

    def applications
      @api_payload.fetch("appointments", []).map do |appointment_hash|
        Appointment.new(application_id: @application_id, **appointment_hash.symbolize_keys.slice(:meeting_point, :appointment_date, :management_url))
      end
    end
  end
end
