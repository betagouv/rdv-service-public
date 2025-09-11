class RdvServicePublicApiClient
  def initialize(api_token)
    @api_token = api_token
  end

  def post(path, params)
    response = Faraday.post(
      "#{ENV['RDV_SERVICE_PUBLIC_OAUTH_BASE_URL']}/api/v1/#{path}",
      params.to_json,
      request_headers
    )

    JSON.parse(response.body)
  end

  def get(path, params = {})
    response = Faraday.get(
      "#{ENV['RDV_SERVICE_PUBLIC_OAUTH_BASE_URL']}/api/v1/#{path}",
      params,
      request_headers
    )

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
