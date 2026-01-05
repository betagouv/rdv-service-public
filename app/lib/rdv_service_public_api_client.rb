class RdvServicePublicApiClient
  def initialize(api_token)
    @api_token = api_token
  end

  def post(path, params)
    connection.post("/api/v1/#{path}", params).body
  end

  def get(path, params = {})
    connection.get("/api/v1/#{path}", params).body
  end

  private

  def connection
    url = ENV.fetch("RDV_SERVICE_PUBLIC_OAUTH_BASE_URL")
    headers = {
      "Authorization" => "Bearer #{@api_token}",
      "Content-Type" => "application/json",
    }

    @connection ||= Faraday.new(url:, headers:) do |builder|
      builder.request :json
      builder.response :json
      builder.response :raise_error # raise an error on 4xx and 5xx responses
      builder.use :sentry_breadcrumbs
    end
  end
end
