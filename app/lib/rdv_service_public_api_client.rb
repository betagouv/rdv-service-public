class RdvServicePublicApiClient
  def initialize(api_token)
    @api_token = api_token
  end

  def post(path, params)
    response = Typhoeus.post(
      "#{ENV['RDV_SERVICE_PUBLIC_OAUTH_BASE_URL']}/api/v1/#{path}",
      body: params.to_json,
      headers: request_headers
    )
    if response.failure?
      Sentry.capture_message("Erreur lors de l'appel à l'api de RDV Service Public")
    end

    JSON.parse(response.body)
  end

  def get(path, params = {})
    response = Typhoeus.get(
      "#{ENV['RDV_SERVICE_PUBLIC_OAUTH_BASE_URL']}/api/v1/#{path}",
      params:,
      headers: request_headers
    )

    if response.failure?
      Sentry.capture_message("Erreur lors de l'appel à l'api de RDV Service Public")
    end

    JSON.parse(response.body)
  end

  private

  def request_headers
    {
      "Authorization" => "Bearer #{@api_token}",
      "Content-Type" => "application/json",
    }
  end
end
