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
    def status(ants_pre_demande_number:, meeting_point_id:, timeout: nil)
      params = {
        application_ids: ants_pre_demande_number,
        meeting_point_id:,
      }
      response_body = request(:get, "status", params:, timeout:)
      response_body.fetch(ants_pre_demande_number)
    end

    def create(ants_pre_demande_number:, meeting_point:, management_url:, appointment_date:, meeting_point_id:)
      request(
        :post,
        "appointments",
        params: {
          application_id: ants_pre_demande_number,
          meeting_point_id: meeting_point_id,
          meeting_point: meeting_point,
          appointment_date: appointment_date,
          management_url: management_url,
        }
      )
    end

    def delete(ants_pre_demande_number:, meeting_point:, appointment_date:, meeting_point_id:)
      request(
        :delete,
        "appointments",
        params: {
          application_id: ants_pre_demande_number,
          appointment_date: appointment_date,
          meeting_point: meeting_point,
          meeting_point_id: meeting_point_id,
        }
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
  end
end
