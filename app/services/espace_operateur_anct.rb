class EspaceOperateurANCT
  ESPACE_OPERATEUR_SERVICE_ID = "49".freeze

  def initialize(siret, account_email, account_type = "user")
    raise "Ce service n’est pas utilisable dans cet environnement." unless ENV.fetch("ESPACE_OPERATEUR_ANCT_AUTH_TOKEN", nil)

    @siret = siret
    @account_email = account_email
    @account_type = account_type
  end

  def organization
    parsed_response&.fetch("organization", nil)
  end

  def operator
    parsed_response&.fetch("operator", nil)
  end

  def can_access?
    return false unless entitlements

    Rails.logger.debug entitlements

    entitlements["can_access"]
  end

  def admin?
    return false unless entitlements

    entitlements["is_admin"]
  end

  def entitlements
    parsed_response&.fetch("entitlements", nil)
  end

  private

  def parsed_response
    @parsed_response ||= JSON.parse(response.body) if response.success?
  end

  def client
    @client ||= Faraday.new(url: "https://operateurs.suite.anct.gouv.fr/api/v1.0/") do |faraday|
      faraday.headers = {
        "X-Service-Auth": ENV.fetch("ESPACE_OPERATEUR_ANCT_AUTH_TOKEN", nil),
      }
    end
  end

  def response
    @response ||= client.get("entitlements/") do |request|
      request.params["service_id"] = ESPACE_OPERATEUR_SERVICE_ID
      request.params["siret"] = @siret
      request.params["account_email"] = @account_email
      request.params["account_type"] = @account_type
    end
  end
end
