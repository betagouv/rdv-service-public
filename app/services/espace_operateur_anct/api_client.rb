class EspaceOperateurANCT::ApiClient
  ESPACE_OPERATEUR_SERVICE_ID = "49".freeze
  ACCOUNT_TYPE = "user"

  def initialize(siret, account_email)
    raise "Ce service n’est pas utilisable dans cet environnement." unless ENV.fetch("ESPACE_OPERATEUR_ANCT_AUTH_TOKEN", nil)

    @siret = siret
    @account_email = account_email
  end

  def organization
    parsed_response["organization"]
  end

  def operator
    parsed_response["operator"]
  end

  def potential_operators
    parsed_response["potentialOperators"]
  end

  def entitlements
    parsed_response["entitlements"]
  end

  def can_access?
    parsed_response.dig("entitlements", "can_access")
  end

  def admin?
    parsed_response.dig("entitlements", "is_admin")
  end

  private

  def parsed_response
    @parsed_response ||= response.success? ? JSON.parse(response.body) : {}
  end

  def client
    @client ||= Faraday.new(url: "https://operateurs.suite.anct.gouv.fr/api/v1.0/") do |faraday|
      faraday.options.timeout = 3
      faraday.options.open_timeout = 3
      faraday.headers = {
        "X-Service-Auth": ENV.fetch("ESPACE_OPERATEUR_ANCT_AUTH_TOKEN", nil),
      }
      faraday.use :sentry_breadcrumbs
    end
  end

  def response
    @response ||= Rails.cache.fetch("EspaceOperateurANCT:#{@siret}:#{@acount_email}", expires_in: 5.seconds) do
      send_request(@siret, @account_email)
    end
  end

  def send_request(siret, account_email)
    client.get("entitlements/") do |request|
      request.params["service_id"] = ESPACE_OPERATEUR_SERVICE_ID
      request.params["siret"] = siret
      request.params["account_email"] = account_email
      request.params["account_type"] = ACCOUNT_TYPE
    end
  end
end
