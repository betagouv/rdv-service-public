class AntsApi
  # Voir la liste des attributs sur la doc API :
  # https://api-coordination.rendezvouspasseport.ants.gouv.fr/docs

  class ApiRequestError < StandardError; end

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

  class << self
    def status(application_id:, timeout: nil)
      response_body = request(:get, "status", params: { application_ids: application_id }, timeout: timeout)

      response_body.fetch(application_id)
    end

    def create(application_id:, meeting_point:, management_url:, appointment_date:, meeting_point_id: nil)
      request(
        :post,
        "appointments",
        params: {
          application_id: application_id,
          meeting_point_id: meeting_point_id,
          meeting_point: meeting_point,
          appointment_date: appointment_date,
          management_url: management_url,
        }
      )
    end

    def delete(application_id:, meeting_point:, appointment_date:, meeting_point_id: nil)
      request(
        :delete,
        "appointments",
        params: {
          application_id: application_id,
          appointment_date: appointment_date,
          meeting_point: meeting_point,
          meeting_point_id: meeting_point_id,
        }
      )
    end

    def find(application_id:, management_url:)
      load_appointments(application_id).find do |data|
        data["management_url"] == management_url
      end
    end

    def find_and_delete(application_id:, management_url:)
      data = find(application_id: application_id, management_url: management_url)
      return if data.blank?

      delete(
        application_id: application_id,
        meeting_point: data["meeting_point"],
        meeting_point_id: data["meeting_point_id"],
        appointment_date: data["appointment_date"]
      )
    end

    private

    def request(method, resource, params:, timeout: nil)
      response = Typhoeus.send(
        method,
        "#{ENV['ANTS_RDV_API_URL']}/#{resource}",
        params: params,
        timeout: timeout,
        headers: {
          "Accept" => "application/json",
          "x-rdv-opt-auth-token" => ENV["ANTS_RDV_OPT_AUTH_TOKEN"],
        }
      )

      unless response.success?
        raise(ApiRequestError, "code:#{response.response_code}, body:#{response.response_body}")
      end

      JSON.parse(response.body)
    end

    def load_appointments(application_id)
      status(application_id: application_id).fetch("appointments")
    end
  end
end
